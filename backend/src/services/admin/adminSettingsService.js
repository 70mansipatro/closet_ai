import AdminSettings from '../../models/AdminSettings.js';

export const getSettings = async () => {
  const settings = await AdminSettings.findOne().lean();
  return settings || { maintenanceMode: { enabled: false, message: '' }, notifications: { announcementBanner: '', templatesPlaceholder: {} } };
};

export const updateSettings = async ({ maintenanceMode, notifications, updatedBy }) => {
  const update = { updatedBy };
  if (maintenanceMode) update.maintenanceMode = maintenanceMode;
  if (notifications) update.notifications = notifications;

  const settings = await AdminSettings.findOneAndUpdate({}, update, { upsert: true, new: true, setDefaultsOnInsert: true });
  return settings;
};
