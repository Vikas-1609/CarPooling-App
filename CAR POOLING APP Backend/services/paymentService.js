const { getCashfree } = require('../config/cashfree');

exports.createCashfreeOrderSession = async (amount, orderId, customer) => {
    const request = {
        order_amount: amount,
        order_currency: process.env.CASHFREE_CURRENCY,
        order_id: `CF_${orderId}_${Date.now()}`,
        customer_details: {
            customer_id: customer.id,
            customer_name: customer.fullName,
            customer_email: customer.email,
            customer_phone: customer.phoneNumber,
        },
        order_meta: {
            return_url: "https://yourflutterapp.com/payment-status?order_id={order_id}",
        },
    };

    try {
        const cashfree = getCashfree();
        const response = await cashfree.PGCreateOrder(request, "2023-08-01");

        if (response.data && response.data.payment_session_id) {
            return {
                cfOrderId: response.data.order_id,
                paymentSessionId: response.data.payment_session_id
            };
        }
        throw new Error(`Cashfree Order Creation Failed: ${JSON.stringify(response.data)}`);

    } catch (error) {
        throw new Error('Payment service error during order creation.');
    }
};

exports.capturePayment = async (cfOrderId, amount) => {
    return { success: true, message: "Standard auto-capture assumed" };
};

exports.voidPayment = async (cfOrderId) => {
    return { success: true, message: "Authorization voided (skipped assuming uncaptured)" };
};

exports.verifyPaymentStatus = async (cfOrderId) => {
    try {
        const cashfree = getCashfree();
        const response = await cashfree.PGOrderFetchPayments(cfOrderId, "2023-08-01");

        const payments = response.data.payments;

        if (!payments || payments.length === 0) {
            return 'NO_TRANSACTION';
        }

        const successPayment = payments.find(p => p.payment_status === 'SUCCESS');
        const pendingPayment = payments.find(p => p.payment_status === 'PENDING');

        if (successPayment) {
            return 'SUCCESS';
        } else if (pendingPayment) {
            return 'PENDING';
        } else {
            return 'FAILED';
        }
    } catch (error) {
        return 'VERIFICATION_ERROR';
    }
};