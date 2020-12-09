const Driver = artifacts.require("Driver");
const truffleAssert = require('truffle-assertions');

contract("Driver Test", async accounts => {
    const driver1 = accounts[0];
    const driver2 = accounts[1];

    const rider1 = accounts[2];

    const request1 = {
        "f_lat": 321,
        "f_long": 321,
        "t_lat": 123,
        "t_long": 123,
        "pickupTime": 1608465600,
        "amount": 10000
    };

    const request_bad = {
        "f_lat": 111,
        "f_long": 111,
        "t_lat": 111,
        "t_long": 111,
        "pickupTime": 1608465600,
        "amount": 10000
    };

    let instance;

    beforeEach("setup constact instance for each test", async () => {
        instance = await Driver.new();

    })

    it("default down payment percentage is 10%", async () => {
        let perc = await instance.getDownPaymentPercentage();

        assert.equal(perc, 10);
    });

    it("default status is closed", async () => {
        let status = await instance.getDriverStatus();

        assert.equal(status, "CLOSED");
    });

    it("should change license plate", async () => {
        const newLicensePlate = "HUNTER1";

        await instance.changeLicensePlate(newLicensePlate);
        let licensePlate = await instance.getLicensePlate();

        assert.equal(licensePlate, newLicensePlate);
    });

    it("should fail because input is outside of 0-100 range", async () => {
        await truffleAssert.fails(
            instance.changeDownPaymentPercentage(115, {
                from: driver1
            }),
            truffleAssert.ErrorType.REVERT
        );
    });

    it("should change down payment percentage", async () => {
        const newPercentage = 15;

        await instance.changeDownPaymentPercentage(newPercentage);
        let percentage = await instance.getDownPaymentPercentage();

        assert.equal(percentage, newPercentage);
    });

    it("only contrct owner can change change driver status to open", async () => {
        await truffleAssert.fails(
            instance.open({
                from: driver2
            }),
            truffleAssert.ErrorType.REVERT
        );
    });

    it("only contrct owner can change change driver status to closed", async () => {
        await truffleAssert.fails(
            instance.close({
                from: driver2
            }),
            truffleAssert.ErrorType.REVERT
        );
    });

    it("should fail because driver is closed", async () => {
        await truffleAssert.fails(
            instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
                from: rider1,
                value: request1.amount / 10
            }), truffleAssert.ErrorType.REVERT
        );
    });

    it("should fail because not enough down payment", async () => {
        await truffleAssert.fails(
            instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
                from: rider1,
                value: request1.amount / 20
            }), truffleAssert.ErrorType.REVERT
        );
    });

    it("should fail because start and end are the same", async () => {
        await truffleAssert.fails(
            instance.sendRequest(request_bad.f_lat, request_bad.f_long, request_bad.t_lat, request_bad.t_long, request_bad.pickupTime, request_bad.amount, {
                from: rider1,
                value: request1.amount / 20
            }), truffleAssert.ErrorType.REVERT
        );
    });

    it("should increment number of requests recieved", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        let numRequests = await instance.getNumRequests();

        assert.equal(numRequests, 1);
    });

    it("should have a status of OPEN for new requests", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        let status = await instance.getRequestStatus(0);

        assert.equal(status, "OPEN");
    });

    it("should have a status of CLOSED for retracted requests", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        await instance.retractRequest(0, {
            from: rider1
        });
        let status = await instance.getRequestStatus(0);

        assert.equal(status, "CLOSED");
    });

    it("should change driver status to BUSY after accepting request", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        await instance.acceptRequest(0, {
            from: driver1
        });
        let status = await instance.getDriverStatus();

        assert.equal(status, "BUSY");
    });

    it("should change driver status to OPEN and request status to CLOSED after cancelling", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        await instance.acceptRequest(0, {
            from: driver1
        });
        await instance.cancelRequest(0, {
            from: driver1
        });
        let driverStatus = await instance.getDriverStatus();
        let status = await instance.getRequestStatus(0);

        assert.equal(driverStatus, "OPEN");
        assert.equal(status, "CLOSED");
    });

    it("should finish requests sucessfully", async () => {
        await instance.open();
        await instance.sendRequest(request1.f_lat, request1.f_long, request1.t_lat, request1.t_long, request1.pickupTime, request1.amount, {
            from: rider1,
            value: request1.amount / 10
        });
        await instance.acceptRequest(0, {
            from: driver1
        });
        await instance.finishRequest(0, {
            from: driver1
        });
        await instance.finishRequest(0, {
            from: rider1,
            value: (request1.amount / 10) * 9
        });
        let driverStatus = await instance.getDriverStatus();
        let status = await instance.getRequestStatus(0);

        assert.equal(driverStatus, "OPEN");
        assert.equal(status, "CLOSED");
    });
});