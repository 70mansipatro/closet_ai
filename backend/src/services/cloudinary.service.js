import cloudinary from '../config/cloudinary.js';

export const uploadToCloudinary = async (buffer, folder = 'closetai') => {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [{ quality: 'auto', fetch_format: 'auto' }],
      },
      (error, result) => {
        if (error) {
          reject(error);
          return;
        }
        resolve(result);
      }
    );

    stream.end(buffer);
  });
};

export const deleteFromCloudinary = async (publicId) => {
  if (!publicId) return null;
  return cloudinary.uploader.destroy(publicId);
};
