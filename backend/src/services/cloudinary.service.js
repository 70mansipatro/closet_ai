import cloudinary from '../config/cloudinary.js';

export const uploadToCloudinary = async (buffer, folder = 'closetai') => {
  console.log('[CLOUDINARY] Upload start', {
    folder,
    bufferSize: buffer?.length ?? 0,
  });

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [{ quality: 'auto', fetch_format: 'auto', width: 1200, crop: 'limit' }],
      },
      (error, result) => {
        if (error) {
          console.error('[CLOUDINARY] Upload error', { folder, error });
          reject(error);
          return;
        }
        console.log('[CLOUDINARY] Upload success', {
          folder,
          publicId: result?.public_id,
          secureUrl: result?.secure_url,
          originalFilename: result?.original_filename,
        });
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
