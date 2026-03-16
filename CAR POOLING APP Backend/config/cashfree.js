const { Cashfree, CFEnvironment } = require('cashfree-pg');

let cashfreeInstance;

const initializeCashfree = () => {
    const env = process.env.CASHFREE_ENV === 'PRODUCTION'
        ? CFEnvironment.PRODUCTION
        : CFEnvironment.SANDBOX;

    cashfreeInstance = new Cashfree(
        env,
        process.env.CASHFREE_CLIENT_ID,
        process.env.CASHFREE_CLIENT_SECRET
    );
};

module.exports = {
    initializeCashfree,
    getCashfree: () => cashfreeInstance
};
