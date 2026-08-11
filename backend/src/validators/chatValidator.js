import Joi from 'joi';
import mongoose from 'mongoose';

export const createConversationSchema = Joi.object({
  title: Joi.string().trim().max(80).default('New chat'),
});

export const sendMessageSchema = Joi.object({
  message: Joi.string().trim().min(1).max(2000).required(),
});

export const validateObjectId = (value) => {
  if (!mongoose.Types.ObjectId.isValid(value)) {
    throw new Error('Invalid id');
  }
  return value;
};
