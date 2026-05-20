local base = import 'base.jsonnet';
local misc = import 'misc.jsonnet';
local pnpm = import 'pnpm.jsonnet';
local yarn = import 'yarn.jsonnet';

{
  /**
   * Creates a complete set of workflows for JavaScript package publishing and testing.
   *
   * Generates three pipelines:
   * 1. 'misc' - Jsonnet validation workflow
   * 2. 'publish-prod' - Production package publishing on branch push
   * 3. 'pr' - Pull request preview publishing and testing
   *
   * @param {array} [repositories=['gynzy']] - The repositories to publish to
   * @param {boolean} [isPublicFork=true] - Whether the repository is a public fork (affects runner selection)
   * @param {boolean} [checkVersionBump=true] - Whether to assert if the version was bumped (recommended)
   * @param {jobs} [testJob=null] - A job to be run during PR to assert tests. Can be an array of jobs
   * @param {string} [branch='main'] - The branch to run the publish-prod job on
   * @param {string} [packageManager='yarn'] - Package manager to use ('yarn' or 'pnpm')
   * @param {string} [image=null] - Docker image override for publish jobs; null uses the PM-specific default
   * @param {array} [buildSteps=null] - Build steps override; null uses the PM-specific default. Pass `[]` to skip build.
   * @returns {workflows} - Complete set of GitHub Actions workflows for JavaScript package lifecycle
   */
  workflowJavascriptPackage(
    repositories=['gynzy'],
    isPublicFork=true,
    checkVersionBump=true,
    testJob=null,
    branch='main',
    packageManager='yarn',
    image=null,
    buildSteps=null,
  )::
    local runsOn = (if isPublicFork then 'ubuntu-latest' else null);
    local defaultImage = if packageManager == 'pnpm' then 'node:24' else 'mirror.gcr.io/node:22';
    local effectiveImage = if image != null then image else defaultImage;
    local defaultBuildSteps = if packageManager == 'pnpm' then [base.step('build', 'pnpm run build')]
                              else [base.step('build', 'yarn build')];
    local effectiveBuildSteps = if buildSteps != null then buildSteps else defaultBuildSteps;
    local pubJob = if packageManager == 'pnpm'
                   then pnpm.pnpmPublishJob(repositories=repositories, runsOn=runsOn, image=effectiveImage, buildSteps=effectiveBuildSteps)
                   else yarn.yarnPublishJob(repositories=repositories, runsOn=runsOn, image=effectiveImage, buildSteps=effectiveBuildSteps);
    local prevJob = if packageManager == 'pnpm'
                    then pnpm.pnpmPublishPreviewJob(repositories=repositories, runsOn=runsOn, checkVersionBump=checkVersionBump, image=effectiveImage, buildSteps=effectiveBuildSteps)
                    else yarn.yarnPublishPreviewJob(repositories=repositories, runsOn=runsOn, checkVersionBump=checkVersionBump, image=effectiveImage, buildSteps=effectiveBuildSteps);

    base.pipeline(
      'misc',
      [misc.verifyJsonnet(fetch_upstream=false, runsOn=runsOn)],
    ) +
    base.pipeline(
      'publish-prod',
      [pubJob],
      event={ push: { branches: [branch] } },
    ) +
    base.pipeline(
      'pr',
      [prevJob] +
      (if testJob != null then
         [testJob]
       else [])
    ),
}
