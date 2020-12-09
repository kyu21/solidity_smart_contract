# Freelance Driving Smart Contract

## Group members:

- Kun Y: kun.yu25@myhunter.cuny.edu

## Purpose of Contract:

Operating a car-for-hire business has many benefits, which include being able to set your own hours and being your own boss. However, in the current climate, this usually involves a third-party middleman used to connect you to customers who can take a significant portion of the money. This smart contract and its associated smart contracts aims to solve that issue by facilating the connection of drivers and customers while only taking a small fee to pay for network costs. This way, the driver gets to keep close to all the money the client is paying for the car ride.

## Logic

This contract helps reinforce trust between 2 parties by enforcing a down payment on the transaction amount to be paid when sending the request. The request can be retracted at any time before the driver accepts it for a refund of the down payment. Furthermore, for the driver to obtain the remaining portion of the transaction amount, acknowledgements of request completion must be recieved by both the driver and rider. The contract also has functionality that allows the driver to stop and start recieving requests mimicking a work day.

## Tests

[Truffle](https://www.trufflesuite.com/docs/truffle/overview) and [truffle-assertions](https://github.com/rkalis/truffle-assertions) are used for this project for testing.  
To run tests, first install dependencies:

```
npm install
```

Then to run tests, in a seperate console window have a [local ETH client](https://github.com/trufflesuite/ganache-cli) running by:

```
npx ganache-cli
```

Then to run tests, run:

```
npm run test
```
