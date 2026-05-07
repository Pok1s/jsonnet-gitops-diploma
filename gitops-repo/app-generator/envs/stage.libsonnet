local defaultParameters = {
  parameters: [],
  settings: {},
};

{
  'diploma-demo-stage': {
    env: 'stage',
    namespace: 'diploma-demo-stage',
    apps: {
      'demo-web': defaultParameters {
        valuesName: 'values-stage',
        appName: 'demo-web-diploma-demo-stage',
      },
    },
  },
}

