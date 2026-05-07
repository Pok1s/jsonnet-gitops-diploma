local defaultParameters = {
  parameters: [],
  settings: {},
};

{
  'diploma-demo-prod': {
    env: 'prod',
    namespace: 'diploma-demo-prod',
    apps: {
      'demo-web': defaultParameters {
        valuesName: 'values-prod',
        appName: 'demo-web-diploma-demo-prod',
      },
    },
  },
}
