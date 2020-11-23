var Dcabs = artifacts.require("./Dcabs.sol");

function getKeccak(prediction, rnd)
{
    var hx = web3.utils.soliditySha3(prediction, rnd);
    return web3.utils.hexToBytes(hx);
}


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
    
    it("CustomerRequest", async () =>
    {
        // accounts[2] is a customer
        
        // 0.00001 degrees = 1.11 m; so we must have a decimal that is accurate to 5 places
        // location can be of the form x1x2<A>x3x4<B>
        
        // Where x1 = 1 for North, 2 for South
        // Where x3 = 1 for East, 2 for West
        // x2 = the number of digits before the decimal place in A
        // x4 = the number of digits before the decimal place in B
        
        // <A> and <B> are numbers that are based on the latitude/longitude value.
        
        // Ex. 8.34627 N 23.34621 E == 11834627122334621
        
        let locationHash = await getKeccak(11834627122334621, 69);
        let destHash = await getKeccak(11839627122334634, 69);
        
        let phoneNoHash = await getKeccak(9176472367, 420);
        
        await this.DcabsObj.setPickup(locationHash, destHash, accounts[1], {from: accounts[2], value: web3.utils.toWei("1")});
        await this.DcabsObj.acceptTrip(phoneNoHash, accounts[2], {from: accounts[1]});
        
        let otp = await this.DcabsObj.cur() - 1;
        assert.equal(otp, 1000, "wrong otp");
        
    })
    
    it("EndTrip", async () =>
    {
        await this.DcabsObj.endTrip(1000, 0, {from: accounts[1]});
        await this.DcabsObj.endTrip(1000, 3, {from: accounts[2]});
        
        let rating = await this.DcabsObj.getDriverRating(accounts[1], {from: accounts[0]});
        assert.equal(rating, 3, "wrong rating");
    })
});
