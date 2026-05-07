local defaultParameters = {
  parameters: [],
  settings: {},
};

{
  'diploma-demo-dev': {
    env: 'dev',
    namespace: 'diploma-demo-dev',
    apps: {
      'demo-web': defaultParameters {
        valuesName: 'values-dev',
        appName: 'demo-web-diploma-demo-dev',
      },
    },
  },
}

