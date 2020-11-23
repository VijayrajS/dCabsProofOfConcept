var Dcabs = artifacts.require("./Dcabs.sol");


// function getRandomHex()
// {
    //     return web3.utils.randomHex(32);
    // }
    
    // function getKeccak(prediction, rnd)
    // {
        //     var hx = web3.utils.soliditySha3(prediction, rnd);
        //     return web3.utils.hexToBytes(hx);
        // }
        
var accounts;
web3.eth.getAccounts().then((acc) =>
{
    accounts = acc;
});

contract("Dcabs_test", function (accounts)
{
    var DcabsObj;
    
    before(async () =>
    {
        this.DcabsObj = await Dcabs.deployed();
        
    })
    
    it("RegisterDriver", async () =>
    {
        const auditorAddr = await this.DcabsObj.auditor();
        assert.equal(accounts[0], auditorAddr, "Wrong auditor");
        await this.DcabsObj.registerDriver(accounts[1], 69);
        assert.equal(accounts[0], auditorAddr);
        
        let nD = await this.DcabsObj.nDrivers();
        assert.equal(nD, 1, "Wrong # of drivers");
        
    })
    
    
});
