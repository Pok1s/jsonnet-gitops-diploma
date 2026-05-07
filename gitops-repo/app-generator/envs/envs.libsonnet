local dev = import 'dev.libsonnet';
local stage = import 'stage.libsonnet';
local prod = import 'prod.libsonnet';

{
  by_file: {
    dev: dev,
    stage: stage,
    prod: prod,
  },
  all: dev + stage + prod,
}

