import User from '../models/User.js';

export const createUser = async (data) => User.create(data);

export const findUserByEmail = async (email) => {
  return User.findOne({ email: email.toLowerCase() });
};

export const findUserById = async (id, select = '') => {
  return User.findById(id).select(select);
};

export const updateUserProfile = async (id, data) => {
  return User.findByIdAndUpdate(id, data, {
    new: true,
    runValidators: true,
  }).select('-password');
};

export const deleteUserById = async (id) => {
  return User.findByIdAndDelete(id);
};
