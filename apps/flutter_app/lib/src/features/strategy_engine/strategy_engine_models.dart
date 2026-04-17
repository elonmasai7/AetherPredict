class StrategyEngineMetrics {
  const StrategyEngineMetrics({
    required this.activeStrategies,
    required this.liveDeployments,
    required this.forecastAccuracy,
    required this.calibrationScore,
  });

  final int activeStrategies;
  final int liveDeployments;
  final double forecastAccuracy;
  final double calibrationScore;

  factory StrategyEngineMetrics.fromJson(Map<String, dynamic> json) {
    return StrategyEngineMetrics(
      activeStrategies: (json['active_strategies'] as num?)?.toInt() ?? 0,
      liveDeployments: (json['live_deployments'] as num?)?.toInt() ?? 0,
      forecastAccuracy: (json['forecast_accuracy'] as num?)?.toDouble() ?? 0,
      calibrationScore: (json['calibration_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CanonCommandModel {
  const CanonCommandModel({
    required this.command,
    required this.summary,
    required this.details,
  });

  final String command;
  final String summary;
  final List<String> details;

  factory CanonCommandModel.fromJson(Map<String, dynamic> json) {
    return CanonCommandModel(
      command: json['command'] as String,
      summary: json['summary'] as String,
      details: (json['details'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class StrategyPipelineStepModel {
  const StrategyPipelineStepModel({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final String status;
  final String detail;

  factory StrategyPipelineStepModel.fromJson(Map<String, dynamic> json) {
    return StrategyPipelineStepModel(
      name: json['name'] as String,
      status: json['status'] as String,
      detail: json['detail'] as String,
    );
  }
}

class StrategyRecordModel {
  const StrategyRecordModel({
    required this.id,
    required this.name,
    required this.prompt,
    required this.templateKey,
    required this.templateName,
    required this.stage,
    required this.market,
    required this.confidence,
    required this.owner,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.pipeline,
    required this.projectPath,
    required this.projectName,
  });

  final String id;
  final String name;
  final String prompt;
  final String templateKey;
  final String templateName;
  final String stage;
  final String market;
  final double confidence;
  final String owner;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<StrategyPipelineStepModel> pipeline;
  final String projectPath;
  final String projectName;

  factory StrategyRecordModel.fromJson(Map<String, dynamic> json) {
    return StrategyRecordModel(
      id: json['id'] as String,
      name: json['name'] as String,
      prompt: json['prompt'] as String? ?? '',
      templateKey: json['template_key'] as String? ?? '',
      templateName: json['template_name'] as String? ?? '',
      stage: json['stage'] as String? ?? '',
      market: json['market'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      owner: json['owner'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      pipeline: (json['pipeline'] as List<dynamic>? ?? [])
          .map((item) =>
              StrategyPipelineStepModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      projectPath: json['project_path'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
    );
  }
}

class StrategyEngineStateModel {
  const StrategyEngineStateModel({
    required this.metrics,
    required this.canonCommands,
    required this.strategies,
  });

  final StrategyEngineMetrics metrics;
  final List<CanonCommandModel> canonCommands;
  final List<StrategyRecordModel> strategies;

  factory StrategyEngineStateModel.fromJson(Map<String, dynamic> json) {
    return StrategyEngineStateModel(
      metrics: StrategyEngineMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>? ?? const {}),
      canonCommands: (json['canon_commands'] as List<dynamic>? ?? [])
          .map((item) => CanonCommandModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      strategies: (json['strategies'] as List<dynamic>? ?? [])
          .map((item) =>
              StrategyRecordModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StrategyTemplateModel {
  const StrategyTemplateModel({
    required this.key,
    required this.name,
    required this.description,
    required this.useCase,
    required this.interfaces,
    required this.ingestionSources,
    required this.confidenceMethod,
    required this.executionHook,
  });

  final String key;
  final String name;
  final String description;
  final String useCase;
  final List<String> interfaces;
  final List<String> ingestionSources;
  final String confidenceMethod;
  final String executionHook;

  factory StrategyTemplateModel.fromJson(Map<String, dynamic> json) {
    return StrategyTemplateModel(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      useCase: json['use_case'] as String,
      interfaces: (json['interfaces'] as List<dynamic>? ?? []).cast<String>(),
      ingestionSources:
          (json['ingestion_sources'] as List<dynamic>? ?? []).cast<String>(),
      confidenceMethod: json['confidence_method'] as String,
      executionHook: json['execution_hook'] as String,
    );
  }
}

class StrategyAgentRoleModel {
  const StrategyAgentRoleModel({
    required this.name,
    required this.job,
    required this.outputs,
  });

  final String name;
  final String job;
  final List<String> outputs;

  factory StrategyAgentRoleModel.fromJson(Map<String, dynamic> json) {
    return StrategyAgentRoleModel(
      name: json['name'] as String,
      job: json['job'] as String,
      outputs: (json['outputs'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class CanonProjectFileModel {
  const CanonProjectFileModel({
    required this.path,
    required this.content,
  });

  final String path;
  final String content;

  factory CanonProjectFileModel.fromJson(Map<String, dynamic> json) {
    return CanonProjectFileModel(
      path: json['path'] as String,
      content: json['content'] as String,
    );
  }
}

class StrategyBuildResultModel {
  const StrategyBuildResultModel({
    required this.strategy,
    required this.agents,
    required this.projectFiles,
  });

  final StrategyRecordModel strategy;
  final List<StrategyAgentRoleModel> agents;
  final List<CanonProjectFileModel> projectFiles;

  factory StrategyBuildResultModel.fromJson(Map<String, dynamic> json) {
    return StrategyBuildResultModel(
      strategy: StrategyRecordModel.fromJson(
          json['strategy'] as Map<String, dynamic>? ?? const {}),
      agents: (json['agents'] as List<dynamic>? ?? [])
          .map((item) =>
              StrategyAgentRoleModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      projectFiles: (json['project_files'] as List<dynamic>? ?? [])
          .map((item) =>
              CanonProjectFileModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StrategyMonitorLogModel {
  const StrategyMonitorLogModel({
    required this.strategyId,
    required this.strategyName,
    required this.timestamp,
    required this.stage,
    required this.message,
    required this.status,
    required this.confidence,
  });

  final String strategyId;
  final String strategyName;
  final DateTime? timestamp;
  final String stage;
  final String message;
  final String status;
  final double confidence;

  factory StrategyMonitorLogModel.fromJson(Map<String, dynamic> json) {
    return StrategyMonitorLogModel(
      strategyId: json['strategy_id'] as String,
      strategyName: json['strategy_name'] as String,
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? ''),
      stage: json['stage'] as String,
      message: json['message'] as String,
      status: json['status'] as String,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StrategyRankingEntryModel {
  const StrategyRankingEntryModel({
    required this.rank,
    required this.strategy,
    required this.accuracy,
    required this.pnl,
    required this.consistency,
    required this.calibration,
    required this.riskAdjustedPerformance,
    required this.status,
  });

  final int rank;
  final String strategy;
  final double accuracy;
  final double pnl;
  final double consistency;
  final double calibration;
  final double riskAdjustedPerformance;
  final String status;

  factory StrategyRankingEntryModel.fromJson(Map<String, dynamic> json) {
    return StrategyRankingEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      strategy: json['strategy'] as String,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
      consistency: (json['consistency'] as num?)?.toDouble() ?? 0,
      calibration: (json['calibration'] as num?)?.toDouble() ?? 0,
      riskAdjustedPerformance:
          (json['risk_adjusted_performance'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
    );
  }
}

class CanonActionResultModel {
  const CanonActionResultModel({
    required this.strategy,
    required this.message,
  });

  final StrategyRecordModel strategy;
  final String message;

  factory CanonActionResultModel.fromJson(Map<String, dynamic> json) {
    return CanonActionResultModel(
      strategy: StrategyRecordModel.fromJson(
          json['strategy'] as Map<String, dynamic>? ?? const {}),
      message: json['message'] as String? ?? '',
    );
  }
}

class CanonProjectExportModel {
  const CanonProjectExportModel({
    required this.projectName,
    required this.exportLabel,
    required this.files,
  });

  final String projectName;
  final String exportLabel;
  final List<CanonProjectFileModel> files;

  factory CanonProjectExportModel.fromJson(Map<String, dynamic> json) {
    return CanonProjectExportModel(
      projectName: json['project_name'] as String? ?? '',
      exportLabel: json['export_label'] as String? ?? '',
      files: (json['files'] as List<dynamic>? ?? [])
          .map((item) =>
              CanonProjectFileModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
