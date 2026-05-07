'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const { createApp } = require('../src/server');

test('health endpoint returns ok', async () => {
  const response = await request(createApp()).get('/healthz').expect(200);
  assert.equal(response.body.status, 'ok');
});

test('info endpoint returns deployment metadata', async () => {
  process.env.APP_VERSION = 'test-version';
  process.env.APP_ENV = 'test';
  process.env.DEPLOYMENT_TIMESTAMP = '2026-05-06T20:00:00.000Z';
  process.env.GIT_SHA = 'abc123';

  const response = await request(createApp()).get('/api/info').expect(200);

  assert.equal(response.body.version, 'test-version');
  assert.equal(response.body.environment, 'test');
  assert.equal(response.body.deploymentTimestamp, '2026-05-06T20:00:00.000Z');
  assert.equal(response.body.commitSha, 'abc123');
});

