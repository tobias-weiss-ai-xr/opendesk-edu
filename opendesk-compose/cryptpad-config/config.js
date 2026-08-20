/* eslint-disable no-unused-vars */
/* eslint-disable no-redeclare */
/* eslint-disable no-prototype-builtins */
/* eslint-disable no-empty */
/* eslint-disable no-var */
/* eslint-disable prefer-const */
/* eslint-disable no-shadow */
/* eslint-disable no-throw-literal */
/* eslint-disable constructor-super */
/* eslint-disable no-ex-assign */
/* eslint-disable no-const-assign */

'use strict';

// Minimal CryptPad configuration for Docker deployment

// Основные настройки доменов
module.exports = {
  httpUnsafeOrigin: 'http://localhost:3000',
  httpSafeOrigin: null, // Используем один домен для локальной разработки

  // Путь к данным
  filePath: '/cryptpad/data',

  // Настройки базы данных
  dbPath: '/cryptpad/data',

  // Временные файлы
  blobPath: '/cryptpad/blob',

  // Настройки администратора (заполняется после первого запуска)
  adminKeys: [],

  // Настройки блокировки IP
  adminEmail: 'admin@localhost',

  // Включить логирование
  log: {
    level: 'info',
  },

  // Настройки пользователя по умолчанию
  defaultStorageLimit: 50 * 1024 * 1024 * 1024, // 50GB

  // Настройки MIME типов
  mimeTypes: {
    pad: [
      // Офисные документы
      'application/pdf',
      'application/ogg',
      'application/oxps',
      'application/pdf',
      'application/vnd.oasis.opendocument.presentation',
      'application/vnd.oasis.opendocument.spreadsheet',
      'application/vnd.oasis.opendocument.text',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-powerpoint',
      'application/vnd.ms-excel',
      'application/msword',
      'application/wordperfect',
      'application/vnd.lotus-wordpro',
      'application/x-iwork-pages-sffpages',
      'application/vnd.apple.pages',
      'application/x-iwork-keynote-sffkey',
      'application/vnd.apple.keynote',
      'application/x-iwork-numbers-sffnumbers',
      'application/vnd.apple.numbers',
      'application/vnd.oasis.opendocument.graphics',
      'application/vnd.oasis.opendocument.chart',
      'application/vnd.oasis.opendocument.formula',
      'application/vnd.oasis.opendocument.database',
      'text/plain',
      'text/rtf',
      'application/vnd.oasis.opendocument.presentation-template',
      'application/vnd.oasis.opendocument.spreadsheet-template',
      'application/vnd.oasis.opendocument.text-template',
      'application/vnd.openxmlformats-officedocument.presentationml.template',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
    ],
  },

  // Настройки параметров приложения
  maxUploadSize: 20 * 1024 * 1024 * 1024, // 20GB

  // Настройки Websocket
  Websocket: {
    pingInterval: 5000,
  },

  // Настройки FormData
  FormData: {
    httpRequestTimeout: 30000,
  },

  // Настройки приложения
  app: {
    pollingInterval: 30000,
    idleTimeout: 0,
  },
};