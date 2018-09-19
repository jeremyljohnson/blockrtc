import web3 from './web3';
import CampaignFactory from './build/CampaignFactory.json';

const instance = new web3.eth.Contract(
    JSON.parse(CampaignFactory.interface),
    '0x7bB0F7917Dca6b63b9E6c798404447eA0DB43435'
);

export default instance;
// 2nd deployed contract (remix): 0x703432c8ca76e59bf3b7642971795cb4309e3cb1
    // '0x428e3b4bC0f5F94d5CCf9Eb7DAd11Ee7Ba621252'
