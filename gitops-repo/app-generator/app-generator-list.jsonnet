local appCatalog = import 'appCatalog.libsonnet';
local envsSource = import 'envs/envs.libsonnet';

local envsFile = std.extVar('envs_file');
local envName = std.extVar('env');
local repoUrl = std.extVar('repo_url');

local envs =
  if envsFile == 'all' then
    envsSource.all
  else if std.objectHas(envsSource.by_file, envsFile) then
    envsSource.by_file[envsFile]
  else
    error 'Unknown envs_file "' + envsFile + '". Known files: all, ' + std.join(', ', std.objectFields(envsSource.by_file));

local envsToGenerate =
  if envName == '' then
    std.objectFields(envs)
  else if std.objectHas(envs, envName) then
    [envName]
  else
    error 'Unknown env "' + envName + '". Known envs: ' + std.join(', ', std.objectFields(envs));

local defaults = {
  argocdNs: 'argocd',
  destServer: 'https://kubernetes.default.svc',
  autoSync: true,
  chartsRepo: repoUrl,
  chartsRevision: 'main',
  azureRegistry: 'pok1sdiplomaacr.azurecr.io',
  helmChart: 'service',
  valuesFullPath: '',
  valuesHelmChartDir: '',
  valuesDir: '',
  valuesNamePattern: 'values-%s',
  appNamePattern: '%s-%s',
  groupName: '',
  imageUpdater: false,
  imageName: '',
  imageUpdaterRegex: '-[0-9a-f]{7}-[0-9]+$',
  imageUpdaterManifestTargets: {
    helm: {
      name: 'image.repository',
      tag: 'image.tag',
    },
  },
};

local valuesNameForEnv(selectedEnvName) = defaults.valuesNamePattern % selectedEnvName;
local appNameForEnv(serviceName, selectedEnvName) = defaults.appNamePattern % [serviceName, selectedEnvName];

local isEmptyOverrideValue(v) =
  v == null ||
  (std.type(v) == 'string' && v == '') ||
  (std.type(v) == 'array' && std.length(v) == 0) ||
  (std.type(v) == 'object' && std.length(std.objectFields(v)) == 0);

local normalizeServiceOverride(overrideObj) = {
  [key]: overrideObj[key]
  for key in std.objectFields(overrideObj)
  if !isEmptyOverrideValue(overrideObj[key])
};

local mergeService(serviceName, envServices) =
  if !std.objectHas(appCatalog, serviceName) then
    error 'Service "' + serviceName + '" is not defined in appCatalog.libsonnet'
  else
    appCatalog[serviceName] + normalizeServiceOverride(envServices[serviceName]);

local mkMergedServices(envServices) = {
  [serviceName]: mergeService(serviceName, envServices)
  for serviceName in std.objectFields(envServices)
};

local resolveDestServer(envCfg) =
  local envDestServer = std.get(envCfg, 'destServer', default='', inc_hidden=false);
  if std.type(envDestServer) == 'string' && envDestServer != '' then envDestServer else defaults.destServer;

local valuesFilePath(serviceName, serviceCfg, valuesName) =
  local valuesFullPath = std.get(serviceCfg, 'valuesFullPath', default=defaults.valuesFullPath, inc_hidden=false);
  local valuesHelmChartDir = std.get(serviceCfg, 'valuesHelmChartDir', default=defaults.valuesHelmChartDir, inc_hidden=false);
  local valuesDir = std.get(serviceCfg, 'valuesDir', default=defaults.valuesDir, inc_hidden=false);
  local dirName = if std.type(valuesDir) == 'string' && valuesDir != '' then valuesDir else serviceName;
  if std.type(valuesFullPath) == 'string' && valuesFullPath != '' then
    valuesFullPath
  else
    '/gitops-repo/values/' + valuesHelmChartDir + dirName + '/' + valuesName + '.yaml';

local commonValuesFilePath(serviceCfg) =
  local dir = std.get(serviceCfg, 'valuesHelmChartDir', default=defaults.valuesHelmChartDir, inc_hidden=false);
  if std.type(dir) == 'string' && dir != '' then
    local project = std.split(dir, '/')[0];
    '/gitops-repo/values/' + project + '/common.yaml'
  else '';

local imageUpdaterGitConfig(serviceCfg) = {
  repository: std.get(serviceCfg, 'imageUpdaterRepository', default=defaults.chartsRepo, inc_hidden=false),
  branch: std.get(serviceCfg, 'imageUpdaterBranch', default=defaults.chartsRevision, inc_hidden=false),
};

local defaultServiceSource(serviceCfg) = {
  repoURL: std.get(serviceCfg, 'repoURL', default=defaults.chartsRepo, inc_hidden=false),
  targetRevision: std.get(serviceCfg, 'targetRevision', default=defaults.chartsRevision, inc_hidden=false),
  path: std.get(serviceCfg, 'helmChartPath', default='gitops-repo/charts/' + std.get(serviceCfg, 'helmChart', default=defaults.helmChart, inc_hidden=false), inc_hidden=false),
};

local mkServiceSource(selectedEnvName, serviceName, serviceCfg) =
  local valuesName = std.get(serviceCfg, 'valuesName', default=valuesNameForEnv(selectedEnvName), inc_hidden=false);
  local commonPath = commonValuesFilePath(serviceCfg);
  defaultServiceSource(serviceCfg) {
    helm: {
      valueFiles:
        (if commonPath != '' then [commonPath] else [])
        + [valuesFilePath(serviceName, serviceCfg, valuesName)],
      parameters: std.get(serviceCfg, 'parameters'),
    },
  };

local mkApplication(selectedEnvName, projectName, envCfg, resolvedDestServer, mergedServices, appName, serviceName, appSettings) =
  {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'Application',
    metadata: {
      name: appName,
      namespace: defaults.argocdNs,
      labels: {
        'app.kubernetes.io/instance': appName,
      },
      finalizers: ['resources-finalizer.argocd.argoproj.io'],
    },
    spec: {
      project: projectName,
      destination: {
        server: resolvedDestServer,
        namespace: envCfg.namespace,
      },
      sources: [mkServiceSource(selectedEnvName, serviceName, mergedServices[serviceName])],
      syncPolicy: {
        syncOptions: ['CreateNamespace=true'],
      } + if std.get(envCfg, 'autoSync', default=defaults.autoSync, inc_hidden=false)
      then { automated: { prune: true, selfHeal: true } }
      else {},
    },
  } + appSettings;

local mkApplications(selectedEnvName, projectName, envCfg, resolvedDestServer, mergedServices) = [
  mkApplication(
    selectedEnvName,
    projectName,
    envCfg,
    resolvedDestServer,
    mergedServices,
    std.get(mergedServices[serviceName], 'appName', default=appNameForEnv(serviceName, selectedEnvName), inc_hidden=false),
    serviceName,
    std.get(mergedServices[serviceName], 'settings', default={})
  )
  for serviceName in std.objectFields(mergedServices)
];

local mkImageUpdater(selectedEnvName, envCfg, mergedServices, serviceName) =
  local serviceCfg = mergedServices[serviceName];
  local appName = std.get(serviceCfg, 'appName', default=appNameForEnv(serviceName, selectedEnvName), inc_hidden=false);
  local valuesName = std.get(serviceCfg, 'valuesName', default=valuesNameForEnv(selectedEnvName), inc_hidden=false);
  {
    apiVersion: 'argocd-image-updater.argoproj.io/v1alpha1',
    kind: 'ImageUpdater',
    metadata: {
      name: appName,
      namespace: defaults.argocdNs,
    },
    spec: {
      namespace: defaults.argocdNs,
      commonUpdateSettings: {
        forceUpdate: true,
        allowTags: 'regexp:^' + std.get(envCfg, 'env', default=selectedEnvName, inc_hidden=false) + defaults.imageUpdaterRegex,
        updateStrategy: 'newest-build',
        pullSecret: 'pullsecret:argocd/regcred',
      },
      writeBackConfig: {
        method: 'git',
        gitConfig: imageUpdaterGitConfig(serviceCfg) {
          writeBackTarget: 'helmvalues:' + valuesFilePath(serviceName, serviceCfg, valuesName),
        },
      },
      applicationRefs: [
        {
          namePattern: appName,
          images: [
            {
              alias: serviceName,
              imageName: defaults.azureRegistry + '/' + serviceCfg.imageName,
              manifestTargets: std.get(serviceCfg, 'imageUpdaterManifestTargets', default=defaults.imageUpdaterManifestTargets, inc_hidden=false),
            },
          ],
        },
      ],
    },
  };

local mkImageUpdaters(selectedEnvName, envCfg, mergedServices) = [
  mkImageUpdater(selectedEnvName, envCfg, mergedServices, serviceName)
  for serviceName in std.objectFields(mergedServices)
  if std.get(mergedServices[serviceName], 'imageUpdater', default=defaults.imageUpdater, inc_hidden=false) &&
     std.get(mergedServices[serviceName], 'imageName', default=defaults.imageName, inc_hidden=false) != ''
];

local mkAppProject(projectName, envCfg, resolvedDestServer) =
  {
    apiVersion: 'argoproj.io/v1alpha1',
    kind: 'AppProject',
    metadata: {
      finalizers: ['resources-finalizer.argocd.argoproj.io'],
      name: projectName,
      namespace: defaults.argocdNs,
    },
    spec: {
      clusterResourceWhitelist: [
        { group: '*', kind: '*' },
      ],
      description: 'Diploma demo environment services',
      destinations: [
        {
          namespace: envCfg.namespace,
          server: resolvedDestServer,
        },
      ],
      sourceRepos: ['*'],
    },
  } + std.get(envCfg, 'AppProjectSettings', default={});

local mkSingleEnvItems(selectedEnvName) =
  local envCfg = envs[selectedEnvName];
  local envServices =
    if std.objectHas(envCfg, 'apps') then envCfg.apps
    else error 'Environment "' + selectedEnvName + '" must contain required "apps" map';
  local projectName = selectedEnvName;
  local mergedServices = mkMergedServices(envServices);
  local resolvedDestServer = resolveDestServer(envCfg);
  std.prune(
    [mkAppProject(projectName, envCfg, resolvedDestServer)]
    + mkApplications(selectedEnvName, projectName, envCfg, resolvedDestServer, mergedServices)
    + mkImageUpdaters(selectedEnvName, envCfg, mergedServices)
  );

{
  apiVersion: 'v1',
  kind: 'List',
  items: std.flattenArrays([mkSingleEnvItems(selectedEnvName) for selectedEnvName in envsToGenerate]),
}
