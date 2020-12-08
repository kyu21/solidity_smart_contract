const Driver = artifacts.require("Driver");

module.exports = function (deployer) {
  deployer
    .deploy(Driver)

    // Option 2) Console log the address:
    .then(() => console.log(Driver.address));
};