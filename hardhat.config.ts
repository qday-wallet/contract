import { HardhatUserConfig, task } from 'hardhat/config';
import '@nomicfoundation/hardhat-chai-matchers';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import 'hardhat-local-networks-config-plugin';
import { setBalance, setCode, time } from '@nomicfoundation/hardhat-network-helpers';
import { TASK_COMPILE, TASK_CLEAN, TASK_TEST } from 'hardhat/builtin-tasks/task-names';

import { poseidonContract } from 'circomlibjs';
import {
  overwriteArtifact,
  exportABIs,
  cleanExportedAbis,
  grantBalance,
  cleanExportedStorageLayouts,
  exportStorageLayouts,
} from './hardhat.utils';
import mocharc from './.mocharc.json';

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1600,
      },
      outputSelection: {
        '*': {
          '*': ['storageLayout'],
        },
      },
    },
  },
  mocha: mocharc,
  gasReporter: {
    enabled: true,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

const exportContractABIs = [
  // Logic
  'contracts/logic/RailgunSmartWallet.sol:RailgunSmartWallet',
  'contracts/adapt/Relay.sol:RelayAdapt',
  // Governance
  'contracts/governance/Getters.sol:Getters',
  'contracts/governance/Staking.sol:Staking',
  'contracts/governance/Voting.sol:Voting',
  'contracts/treasury/GovernorRewards.sol:GovernorRewards',
];

const exportContractStorageLayouts = [
  // Logic
  'contracts/logic/RailgunSmartWallet.sol:RailgunSmartWallet',
  // Governance
  'contracts/treasury/Treasury.sol:Treasury',
  'contracts/treasury/GovernorRewards.sol:GovernorRewards',
];

task(TASK_COMPILE).setAction(async (taskArguments, hre, runSuper) => {
  await runSuper();
  await overwriteArtifact(
    hre,
    'contracts/logic/Poseidon.sol:PoseidonT3',
    poseidonContract.createCode(2),
  );
  await overwriteArtifact(
    hre,
    'contracts/logic/Poseidon.sol:PoseidonT4',
    poseidonContract.createCode(3),
  );
  await hre.run('abi-export');
  await hre.run('storage-layout-export');
});

task(TASK_CLEAN).setAction(async (taskArguments, hre, runSuper) => {
  await runSuper();
  await hre.run('abi-clean');
  await hre.run('storage-layout-clean');
});

task('abi-clean', 'Clean exported ABI artifacts').setAction((taskArguments, hre) => {
  return new Promise((resolve) => {
    cleanExportedAbis(hre);
    resolve(null);
  });
});

task('abi-export', 'Export ABI artifacts').setAction(async (taskArguments, hre) => {
  await exportABIs(hre, exportContractABIs);
});

task(TASK_TEST, 'Runs test suite')
  .addOptionalParam(
    'longtests',
    'no = execute shorter tests; no = full test suite enabled (default: yes)',
  )
  .setAction(async (taskArguments: { longtests: string }, hre, runSuper) => {
    if (taskArguments.longtests === 'no' || taskArguments.longtests === 'yes') {
      process.env.LONG_TESTS = taskArguments.longtests;
    } else if (process.env.LONG_TESTS !== 'no') {
      process.env.LONG_TESTS = 'yes';
    }
    await runSuper();
  });

task('accounts', 'Prints the list of accounts', async (taskArguments, hre) => {
  const accounts = await hre.ethers.getSigners();
  accounts.forEach((account) => {
    console.log(account.address);
  });
});

task('deploy:test', 'Deploy full deployment for testing purposes', async (taskArguments, hre) => {
  await hre.run('run', { script: 'scripts/deploy_test.ts' });
});

task('set-token-balance', 'Sets balance of ERC20 token')
  .addParam('address', 'Address to set balance for')
  .addParam('token', 'Token address to set balance on')
  .addParam('balance', 'Balance to set')
  .setAction(
    async (
      { address, token, balance }: { address: string; token: string; balance: string },
      hre,
    ) => {
      await grantBalance(hre, address, token, BigInt(balance));
    },
  );

task('set-eth-balance', 'Sets ETH balance')
  .addParam('address', 'Address to set balance for')
  .addParam('balance', 'Balance to set')
  .setAction(async ({ address, balance }: { address: string; balance: string }, hre) => {
    await setBalance(address, hre.ethers.BigNumber.from(balance).toHexString());
  });

task('set-code', 'Sets contract code for address')
  .addParam('address', 'Address to set code for')
  .addParam('contract', 'Contract to set at address')
  .setAction(async ({ address, contract }: { address: string; contract: string }, hre) => {
    const code = await hre.artifacts.readArtifact(contract);
    await setCode(address, code.bytecode);
  });

task('fastforward', 'Fast forwards time')
  .addParam('days', 'Days to fast forward (accepts decimal values)')
  .setAction(async (taskArguments: { days: string }) => {
    await time.increase(86400 * Number(taskArguments.days));
    console.log(`Fast forwarded ${taskArguments.days} days`);
  });

task('storage-layout-clean', 'Clean exported storage layouts').setAction((taskArguments, hre) => {
  return new Promise((resolve) => {
    cleanExportedStorageLayouts(hre);
    resolve(null);
  });
});

task('storage-layout-export', 'Export storage layouts').setAction(async (taskArguments, hre) => {
  await exportStorageLayouts(hre, exportContractStorageLayouts);
});

task(
  'load-debug-info',
  'Loads debug info into hardhat node for better errors in fork mode',
).setAction(async (taskArguments, hre) => {
  const list = await hre.artifacts.getAllFullyQualifiedNames();
  for (const fqn of list) {
    console.log(`Loading debug artifacts for ${fqn}`);
    const buildInfo = await hre.artifacts.getBuildInfo(fqn);
    await hre.ethers.provider.send('hardhat_addCompilationResult', [
      buildInfo?.solcVersion,
      buildInfo?.input,
      buildInfo?.output,
    ]);
  }
});

export default config;
