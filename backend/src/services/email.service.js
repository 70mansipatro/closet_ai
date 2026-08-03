import nodemailer from 'nodemailer';

const createTransporter = () => {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    return null;
  }

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
};

export const sendOtpEmail = async (email, otp) => {
  const transporter = createTransporter();
  if (!transporter) {
    console.warn('SMTP credentials not configured; skipping email send');
    return;
  }

  await transporter.sendMail({
    from: process.env.SMTP_FROM || 'no-reply@closetai.app',
    to: email,
    subject: 'ClosetAI password reset OTP',
    html: `<p>Your ClosetAI verification code is <strong>${otp}</strong>.</p>`,
  });
};
