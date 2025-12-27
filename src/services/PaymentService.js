const oracledb = require('oracledb');
const BaseService = require('./BaseService');
const { getConnection } = require('../config/database');

/**
 * PaymentService - Service for IB.BOPayment Oracle package
 * Handles payment search and details operations
 */
class PaymentService extends BaseService {
    constructor() {
        super('BOPayment');
    }

    /**
     * Find payments with various filters
     * @param {Object} filters - Payment search filters
     * @returns {Promise<Array>} Array of payments matching criteria
     */
    async find(filters = {}) {
        console.log('[PaymentService] Calling BOPayment.find()');

        const binds = {
            // Remitter
            P_CUST_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.custId || null
            },
            P_CUST_NAME: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.custName || null
            },
            P_USER_LOGIN: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.userLogin || null
            },
            P_OFFICER_ID: {
                type: oracledb.NUMBER,
                dir: oracledb.BIND_IN,
                val: filters.officerId || null
            },
            // Payment
            P_BEN_NAME: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.benName || null
            },
            P_FROM_CONTRACT: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.fromContract || null
            },
            P_FROM_LOCATION: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.fromLocation || null
            },
            P_PMT_DETAILS: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.pmtDetails || null
            },
            P_AMOUNT_FROM: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.amountFrom || null
            },
            P_AMOUNT_TILL: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.amountTill || null
            },
            P_CURRENCIES: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.currencies || null
            },
            P_PMT_CLASS: {
                type: oracledb.STRING,
                dir: oracledb.BIND_INOUT,
                val: filters.pmtClass || null
            },
            P_EFFECT_FROM: {
                type: oracledb.DATE,
                dir: oracledb.BIND_IN,
                val: filters.effectFrom || null
            },
            P_EFFECT_TILL: {
                type: oracledb.DATE,
                dir: oracledb.BIND_IN,
                val: filters.effectTill || null
            },
            // System
            P_PAYMENT_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.paymentId || null
            },
            P_CHANNELS: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.channels || null
            },
            P_STATUSES: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: filters.statuses || null
            },
            P_CREATED_FROM: {
                type: oracledb.DATE,
                dir: oracledb.BIND_IN,
                val: filters.createdFrom || null
            },
            P_CREATED_TILL: {
                type: oracledb.DATE,
                dir: oracledb.BIND_IN,
                val: filters.createdTill || null
            },
            P_CURSOR: {
                type: oracledb.CURSOR,
                dir: oracledb.BIND_OUT
            }
        };

        const connection = await getConnection();
        try {
            const result = await connection.execute(
                `BEGIN :P_CURSOR := ${this.packageName}.find(
                    :P_CUST_ID, :P_CUST_NAME, :P_USER_LOGIN, :P_OFFICER_ID,
                    :P_BEN_NAME, :P_FROM_CONTRACT, :P_FROM_LOCATION, :P_PMT_DETAILS,
                    :P_AMOUNT_FROM, :P_AMOUNT_TILL, :P_CURRENCIES, :P_PMT_CLASS,
                    :P_EFFECT_FROM, :P_EFFECT_TILL,
                    :P_PAYMENT_ID, :P_CHANNELS, :P_STATUSES, :P_CREATED_FROM, :P_CREATED_TILL
                ); END;`,
                binds,
                { outFormat: oracledb.OUT_FORMAT_OBJECT }
            );

            const resultSet = result.outBinds.P_CURSOR;
            const rows = await resultSet.getRows();
            await resultSet.close();

            console.log(`[PaymentService] find returned ${rows.length} rows`);
            return {
                payments: rows,
                pmtClass: result.outBinds.P_PMT_CLASS
            };
        } finally {
            await connection.close();
        }
    }

    /**
     * Get detailed payment information by ID
     * @param {string} paymentId - Payment ID
     * @returns {Promise<Object>} Payment details
     */
    async getPaymentDetails(paymentId) {
        console.log(`[PaymentService] Getting payment details for: ${paymentId}`);

        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: paymentId
            },
            P_USER_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_USER_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_OFFICER_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_GOLD_MANAGER: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_CUST_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_CUST_ACCOUNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_RES: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_CITY: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_STREET: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_ACNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_TYPE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ORD_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ORD_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ORD_RES: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ORD_ACNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_BANK_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_BANK_BRANCH: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_BANK_SWIFT_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_BANK_OTHER_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_BANK_ADDR: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IM_BANK_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IM_BANK_ACNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IM_BANK_SWIFT_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IM_BANK_OTHER_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IM_BANK_ADDR: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_PAYMENT_DETAILS: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ITB: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ITC: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_EPC: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ITD: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_EXCHANGE_RATE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_COM_TYPE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_TYPE_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_E_CHEQUE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_E_EXPIRY: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_SIGN_TIME: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_SIGN_RSA: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_TEMPLATE_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_GLOBUS_FT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BOOKING_DATE: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_EXEC_DATE: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_TAX_PAYER_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_IS_TAX_DOC: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_IS_UT_PAYMENT: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_UT_TARIF_TYPE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_TARIF_PRICE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_TARIF_AMOUNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_OVER_AMOUNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_PENALTY_TYPE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_PENALTY_DAYS: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_UT_PENALTY_AMNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_BOOKING_DATE: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_UT_DATE_START: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_UT_DATE_END: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_UT_VOLUME_START: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_VOLUME_END: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_QUANTITY: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_CORP_CUST_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_CORP_CUST_BRANCH: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_BILL_NUMBER: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_UT_PHONE_NUMBER: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ABONENT_CODE: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ABONENT_NAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ABONENT_SURNAME: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ABONENT_ACCOUNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_ABONENT_LEGAL_ID: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_LOCATION: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_SAVING_ACC_CHARGE_ID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_REJECTOR: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_REJECT_DATE: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_CHARGES_ACCOUNT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_SALARY_PAYMENT_DATE: { type: oracledb.DATE, dir: oracledb.BIND_OUT },
            P_SECTOR: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
            P_SEGMENT: { type: oracledb.STRING, dir: oracledb.BIND_OUT },
            P_BEN_MOBILE: { type: oracledb.STRING, dir: oracledb.BIND_OUT }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.payment(
                    :P_ID, :P_USER_NAME, :P_USER_ID, :P_OFFICER_NAME, :P_GOLD_MANAGER,
                    :P_CUST_NAME, :P_CUST_ACCOUNT, :P_BEN_NAME, :P_BEN_ID, :P_BEN_RES,
                    :P_BEN_CITY, :P_BEN_STREET, :P_BEN_ACNT, :P_BEN_TYPE, :P_ORD_NAME,
                    :P_ORD_ID, :P_ORD_RES, :P_ORD_ACNT, :P_BEN_BANK_NAME, :P_BEN_BANK_BRANCH,
                    :P_BEN_BANK_SWIFT_CODE, :P_BEN_BANK_OTHER_CODE, :P_BEN_BANK_ADDR,
                    :P_IM_BANK_NAME, :P_IM_BANK_ACNT, :P_IM_BANK_SWIFT_CODE,
                    :P_IM_BANK_OTHER_CODE, :P_IM_BANK_ADDR, :P_PAYMENT_DETAILS,
                    :P_ITB, :P_ITC, :P_EPC, :P_ITD, :P_EXCHANGE_RATE, :P_COM_TYPE,
                    :P_TYPE_ID, :P_E_CHEQUE, :P_E_EXPIRY, :P_SIGN_TIME, :P_SIGN_RSA,
                    :P_TEMPLATE_NAME, :P_GLOBUS_FT, :P_BOOKING_DATE, :P_EXEC_DATE,
                    :P_TAX_PAYER_ID, :P_IS_TAX_DOC, :P_IS_UT_PAYMENT, :P_UT_TARIF_TYPE,
                    :P_UT_TARIF_PRICE, :P_UT_TARIF_AMOUNT, :P_UT_OVER_AMOUNT,
                    :P_UT_PENALTY_TYPE, :P_UT_PENALTY_DAYS, :P_UT_PENALTY_AMNT,
                    :P_UT_BOOKING_DATE, :P_UT_DATE_START, :P_UT_DATE_END,
                    :P_UT_VOLUME_START, :P_UT_VOLUME_END, :P_UT_QUANTITY,
                    :P_UT_CORP_CUST_CODE, :P_UT_CORP_CUST_BRANCH, :P_UT_BILL_NUMBER,
                    :P_UT_PHONE_NUMBER, :P_ABONENT_CODE, :P_ABONENT_NAME,
                    :P_ABONENT_SURNAME, :P_ABONENT_ACCOUNT, :P_ABONENT_LEGAL_ID,
                    :P_LOCATION, :P_SAVING_ACC_CHARGE_ID, :P_REJECTOR, :P_REJECT_DATE,
                    :P_CHARGES_ACCOUNT, :P_SALARY_PAYMENT_DATE, :P_SECTOR, :P_SEGMENT, :P_BEN_MOBILE
                ); END;`,
                binds
            );

            // Convert output binds to camelCase object
            const details = {
                userName: binds.P_USER_NAME.val,
                userId: binds.P_USER_ID.val,
                officerName: binds.P_OFFICER_NAME.val,
                goldManager: binds.P_GOLD_MANAGER.val,
                custName: binds.P_CUST_NAME.val,
                custAccount: binds.P_CUST_ACCOUNT.val,
                benName: binds.P_BEN_NAME.val,
                benId: binds.P_BEN_ID.val,
                benRes: binds.P_BEN_RES.val,
                benCity: binds.P_BEN_CITY.val,
                benStreet: binds.P_BEN_STREET.val,
                benAcnt: binds.P_BEN_ACNT.val,
                benType: binds.P_BEN_TYPE.val,
                ordName: binds.P_ORD_NAME.val,
                ordId: binds.P_ORD_ID.val,
                ordRes: binds.P_ORD_RES.val,
                ordAcnt: binds.P_ORD_ACNT.val,
                benBankName: binds.P_BEN_BANK_NAME.val,
                benBankBranch: binds.P_BEN_BANK_BRANCH.val,
                benBankSwiftCode: binds.P_BEN_BANK_SWIFT_CODE.val,
                benBankOtherCode: binds.P_BEN_BANK_OTHER_CODE.val,
                benBankAddr: binds.P_BEN_BANK_ADDR.val,
                imBankName: binds.P_IM_BANK_NAME.val,
                imBankAcnt: binds.P_IM_BANK_ACNT.val,
                imBankSwiftCode: binds.P_IM_BANK_SWIFT_CODE.val,
                imBankOtherCode: binds.P_IM_BANK_OTHER_CODE.val,
                imBankAddr: binds.P_IM_BANK_ADDR.val,
                paymentDetails: binds.P_PAYMENT_DETAILS.val,
                itb: binds.P_ITB.val,
                itc: binds.P_ITC.val,
                epc: binds.P_EPC.val,
                itd: binds.P_ITD.val,
                exchangeRate: binds.P_EXCHANGE_RATE.val,
                comType: binds.P_COM_TYPE.val,
                typeId: binds.P_TYPE_ID.val,
                eCheque: binds.P_E_CHEQUE.val,
                eExpiry: binds.P_E_EXPIRY.val,
                signTime: binds.P_SIGN_TIME.val,
                signRSA: binds.P_SIGN_RSA.val,
                templateName: binds.P_TEMPLATE_NAME.val,
                globusFt: binds.P_GLOBUS_FT.val,
                bookingDate: binds.P_BOOKING_DATE.val,
                execDate: binds.P_EXEC_DATE.val,
                taxPayerId: binds.P_TAX_PAYER_ID.val,
                isTaxDoc: binds.P_IS_TAX_DOC.val,
                isUtPayment: binds.P_IS_UT_PAYMENT.val,
                utTarifType: binds.P_UT_TARIF_TYPE.val,
                utTarifPrice: binds.P_UT_TARIF_PRICE.val,
                utTarifAmount: binds.P_UT_TARIF_AMOUNT.val,
                utOverAmount: binds.P_UT_OVER_AMOUNT.val,
                utPenaltyType: binds.P_UT_PENALTY_TYPE.val,
                utPenaltyDays: binds.P_UT_PENALTY_DAYS.val,
                utPenaltyAmnt: binds.P_UT_PENALTY_AMNT.val,
                utBookingDate: binds.P_UT_BOOKING_DATE.val,
                utDateStart: binds.P_UT_DATE_START.val,
                utDateEnd: binds.P_UT_DATE_END.val,
                utVolumeStart: binds.P_UT_VOLUME_START.val,
                utVolumeEnd: binds.P_UT_VOLUME_END.val,
                utQuantity: binds.P_UT_QUANTITY.val,
                utCorpCustCode: binds.P_UT_CORP_CUST_CODE.val,
                utCorpCustBranch: binds.P_UT_CORP_CUST_BRANCH.val,
                utBillNumber: binds.P_UT_BILL_NUMBER.val,
                utPhoneNumber: binds.P_UT_PHONE_NUMBER.val,
                abonentCode: binds.P_ABONENT_CODE.val,
                abonentName: binds.P_ABONENT_NAME.val,
                abonentSurname: binds.P_ABONENT_SURNAME.val,
                abonentAccount: binds.P_ABONENT_ACCOUNT.val,
                abonentLegalId: binds.P_ABONENT_LEGAL_ID.val,
                location: binds.P_LOCATION.val,
                savingAccChargeId: binds.P_SAVING_ACC_CHARGE_ID.val,
                rejector: binds.P_REJECTOR.val,
                rejectDate: binds.P_REJECT_DATE.val,
                chargesAccount: binds.P_CHARGES_ACCOUNT.val,
                salaryPaymentDate: binds.P_SALARY_PAYMENT_DATE.val,
                sector: binds.P_SECTOR.val,
                segment: binds.P_SEGMENT.val,
                benMobile: binds.P_BEN_MOBILE.val
            };

            console.log('[PaymentService] Payment details retrieved successfully');
            return details;
        } finally {
            await connection.close();
        }
    }

    /**
     * Change template group for a payment
     * @param {string} paymentId - Payment ID
     * @param {string} groupId - Group ID
     * @returns {Promise<Object>} Result with success indicator
     */
    async changeTemplateGroup(paymentId, groupId) {
        console.log(`[PaymentService] Changing template group for payment: ${paymentId}`);

        const binds = {
            P_ID: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: paymentId
            },
            P_GROUP: {
                type: oracledb.STRING,
                dir: oracledb.BIND_IN,
                val: groupId
            }
        };

        const connection = await getConnection();
        try {
            await connection.execute(
                `BEGIN ${this.packageName}.change_template_group(:P_ID, :P_GROUP); END;`,
                binds
            );

            await connection.commit();

            return {
                success: true,
                paymentId,
                groupId
            };
        } finally {
            await connection.close();
        }
    }
}

module.exports = PaymentService;