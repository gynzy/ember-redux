{
  database_servers: {
      test: {
          server: 'test-ams',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'test-ams-8': {
          server: 'test-ams-8',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'eu-w4-unicorn-production': {
          server: 'eu-w4-unicorn-production',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'eu-w4-responses-production' : {
          server: 'eu-w4-responses-production',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'eu-w4-metrics-production' : {
          server: 'eu-w4-metrics-production',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'gynzy-test' : {
          server: 'gynzy-test',
          region: 'europe-west4',
          project: 'gynzy-1090',
      },
      'gynzy-production' : {
          server: 'gynzy-production',
          region: 'europe-west4',
          project: 'gynzy-1090',
      },
      'accounts-production': {
          server: 'eu-w4-accounts-production',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'eu-w4-licenses-v8' : {
          server: 'eu-w4-licenses-v8',
          region: 'europe-west4',
          project: 'unicorn-985',
      },
      'eu-w4-curriculum-v8': {
          server: 'eu-w4-curriculum-v8',
          region: 'europe-west4',
          project: 'unicorn-985',
      }
  },

  copyDatabase(mysqlActionOptions)::
    assert std.length(std.findSubstr('_pr_', mysqlActionOptions.database_name_target)) > 0; // target db gets deleted. must contain _pr_

    // overwrite and set task to clone
    // delete database by setting it to null and calling prune afterwards
    local pluginOptions = std.prune(mysqlActionOptions + { task: 'clone', database: null });

    $.action('copy-database', $.mysql_action_image,
      with=pluginOptions
    ),

  deleteDatabase(mysqlActionOptions)::
    assert std.length(std.findSubstr('_pr_', mysqlActionOptions.database_name_target)) > 0; // this fn deletes the database. destination db must contain _pr_

    // overwrite and set task to clone
    // delete database by setting it to null and calling prune afterwards
    local pluginOptions = std.prune(mysqlActionOptions + { task: 'remove', database: null });

    $.action('delete-database', $.mysql_action_image,
      with=pluginOptions
    ),
}