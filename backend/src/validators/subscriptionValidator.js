import Joi from 'joi';

export const createOrderSchema = Joi.object({
  planCode: Joi.string().trim().required(),
});

export const verifyPaymentSchema = Joi.object({
  orderId: Joi.string().trim().required(),
  paymentId: Joi.string().trim().required(),
  signature: Joi.string().trim().required(),
  planCode: Joi.string().trim().required(),
});
