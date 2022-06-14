import Vue from 'vue/dist/vue';
import { ethers } from 'ethers';
import Staking from '../build/contracts/Staking.json';
import './style.css';

new Vue({
  el: '#app',
  data: () => ({
    /**
     * contract data
     */
    web3Provider: null,
    account: null,
    accountBalance: null,
    contractBalance: null,
    rewardRate: null,
    isStakeholder: null,
    stakes: null,
    /**
     * form data
     */
    amount: '',
  }),
  computed: {
    signer() {
      return this.web3Provider.getSigner();
    },
    contract() {
      return new ethers.Contract(import.meta.env.VITE_CONTRACT_ADDRESS, Staking.abi, this.signer);
    },
    decimals() {
      return 18;
    },
  },
  created() {
    if (!window.ethereum) {
      console.log('Please connect to Metamask.');
      return;
    }
    this.init();
  },
  methods: {
    async init() {
      await this.loadWeb3Provider();
      await this.loadAccount();
      if (this.account) await this.loadData();
    },
    async loadWeb3Provider() {
      this.web3Provider = new ethers.providers.Web3Provider(window.ethereum);
      this.web3Provider.provider.on('accountsChanged', () => this.init());
    },
    async loadAccount() {
      const [account] = await this.web3Provider.send('eth_requestAccounts');
      this.account = account;
    },
    async loadData() {
      this.accountBalance = await this.web3Provider.getBalance(this.account);
      this.contractBalance = await this.contract.contractBalance();
      this.rewardRate = await this.contract.rewardRate();
      this.isStakeholder = await this.contract.isStakeholder(this.account);
      if (this.isStakeholder) {
        this.stakes = await this.contract.stakes(this.account);
      }
    },
    async deposit() {
      const amount = ethers.BigNumber.from(1).mul(ethers.FixedNumber.fromString(this.amount));
      const res = await this.contract.deposit({
        value: amount,
      });
      await res.wait();
      window.location.reload();
    },
    async claim() {
      const res = await this.contract.claim();
      await res.wait();
      window.location.reload();
    },
    estimatedRewards() {
      let reward = 0;
      for (let i = 0; i < this.stakes.length; i += 1) {
        const { lastClaimDate, amount } = this.stakes[i];
        reward += (((Math.floor(+new Date() / 1000) - lastClaimDate) * amount) * this.rewardRate) / 100 / 365 / 86400;
      }
      return reward;
    },
    formatNumber(number = 0) {
      return Number(number / (10 ** this.decimals)).toFixed(6);
    },
  },
});

Vue.component('TextUpdater', {
  name: 'TextUpdater',
  props: {
    text: {
      type: Function,
      default: () => {},
    },
  },
  data: () => ({
    display: '',
  }),
  created() {
    const timer = setInterval(() => {
      if (this.display === this.text()) {
        clearInterval(timer);
        return;
      }
      this.display = this.text();
    }, 1000);
  },
  template: '<span>{{ display }}</span>',
});

window.onload = () => document.body.removeAttribute('hidden');
