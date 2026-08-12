import nodemailer from 'nodemailer';
import { AppError } from '../utils/appError.js';

const getSmtpConfig = () => ({
  service: process.env.SMTP_SERVICE,
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  user: process.env.SMTP_USER,
  pass: process.env.SMTP_PASS,
  from: process.env.SMTP_FROM || process.env.SMTP_USER,
});

const assertSmtpConfigured = (config) => {
  const missing = [];
  if (!config.user) missing.push('SMTP_USER');
  if (!config.pass) missing.push('SMTP_PASS');
  if (!config.service && !config.host) missing.push('SMTP_SERVICE or SMTP_HOST');

  if (missing.length) {
    console.error('[EMAIL SERVICE] SMTP email configuration is incomplete', { missing });
    throw new AppError('SMTP email configuration is incomplete.', 500);
  }
};

const createTransporter = (config) => {
  // SMTP_SERVICE (e.g. "gmail") lets nodemailer resolve host/port itself —
  // recommended when using a Gmail App Password.
  if (config.service) {
    return nodemailer.createTransport({
      service: config.service,
      auth: { user: config.user, pass: config.pass },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 10000,
    });
  }

  const secure = config.port === 465;
  return nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure, // true for port 465 (TLS), false for 587/25 (STARTTLS)
    requireTLS: !secure,
    auth: { user: config.user, pass: config.pass },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
};

const buildOtpEmail = (otp) => {
  const text = [
    'ClosetAI',
    '',
    'Your password reset verification code is:',
    '',
    otp,
    '',
    'This code expires in 10 minutes.',
    '',
    'If you did not request this password reset, you can safely ignore this email.',
  ].join('\n');

  const html = `
    <div style="font-family: Arial, Helvetica, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px 24px; color: #1a1a1a;">
      <h2 style="margin: 0 0 24px; color: #1a2b4c; letter-spacing: 0.5px;">ClosetAI</h2>
      <p style="font-size: 15px; margin: 0 0 16px;">Your password reset verification code is:</p>
      <div style="font-size: 32px; font-weight: bold; letter-spacing: 6px; background: #f2f4f8; color: #1a2b4c; padding: 16px 24px; border-radius: 8px; text-align: center; margin: 0 0 16px;">
        ${otp}
      </div>
      <p style="font-size: 14px; color: #555; margin: 0 0 24px;">This code expires in 10 minutes.</p>
      <p style="font-size: 13px; color: #888; margin: 0;">If you did not request this password reset, you can safely ignore this email.</p>
    </div>
  `;

  return { text, html };
};

const classifySmtpError = (error) => {
  if (error.code === 'EAUTH' || error.responseCode === 535) return 'authentication failed';
  if (error.code === 'ETIMEDOUT') return 'connection timed out';
  if (error.code === 'ECONNECTION' || error.code === 'ESOCKET') return 'connection error';
  if (error.responseCode >= 500 && error.responseCode < 600) return 'rejected by mail server';
  return 'unknown error';
};

export const sendOtpEmail = async (email, otp) => {
  const config = getSmtpConfig();
  assertSmtpConfigured(config);

  console.log('[EMAIL SERVICE] attempting to send OTP email', {
    host: config.host || `service:${config.service}`,
    port: config.port,
    user: config.user,
    to: email,
  });

  const transporter = createTransporter(config);

  try {
    await transporter.verify();
    console.log('[EMAIL SERVICE] SMTP connection verified successfully');

    const { text, html } = buildOtpEmail(otp);
    const info = await transporter.sendMail({
      from: `"ClosetAI" <${config.from}>`,
      to: email,
      subject: 'ClosetAI Password Reset Verification Code',
      text,
      html,
    });

    console.log('[EMAIL SERVICE] OTP email sent successfully', {
      to: email,
      messageId: info?.messageId,
    });
  } catch (error) {
    console.error('[EMAIL SERVICE] Failed to send OTP email', {
      to: email,
      reason: classifySmtpError(error),
      code: error.code,
      command: error.command,
      responseCode: error.responseCode,
      message: error.message,
    });
    throw new AppError('Failed to send the verification email. Please try again later.', 502);
  }
};
