import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _webAppVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '');
const _webBuildNumber =
    String.fromEnvironment('BUILD_NUMBER', defaultValue: '');
const _webCommitHash =
    String.fromEnvironment('GIT_COMMIT_HASH', defaultValue: '');
const _webShortHash =
    String.fromEnvironment('GIT_SHORT_HASH', defaultValue: '');
const _webBranch = String.fromEnvironment('GIT_BRANCH', defaultValue: '');
const _webCommitDate =
    String.fromEnvironment('GIT_COMMIT_DATE', defaultValue: '');

class VersionInfo {
  final String appVersion;
  final String buildNumber;
  final String commitHash;
  final String shortHash;
  final String branch;
  final String commitMessage;
  final String commitDate;
  final String commitAuthor;
  final bool hasGitInfo;

  VersionInfo({
    required this.appVersion,
    required this.buildNumber,
    required this.commitHash,
    required this.shortHash,
    required this.branch,
    required this.commitMessage,
    required this.commitDate,
    required this.commitAuthor,
    required this.hasGitInfo,
  });

  Map<String, dynamic> toJson() => {
        'app_version': appVersion,
        'build_number': buildNumber,
        'commit_hash': commitHash,
        'short_hash': shortHash,
        'branch': branch,
        'commit_message': commitMessage,
        'commit_date': commitDate,
        'commit_author': commitAuthor,
        'has_git_info': hasGitInfo,
      };
}

class VersionService {
  static Future<VersionInfo> getVersionInfo() async {
    // Get package info (app version)
    final packageInfo = await PackageInfo.fromPlatform();

    String appVersion = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    String commitHash = 'unknown';
    String shortHash = 'unknown';
    String branch = 'unknown';
    String commitMessage = 'unknown';
    String commitDate = 'unknown';
    String commitAuthor = 'unknown';
    bool hasGitInfo = false;

    if (kIsWeb) {
      // Web cannot inspect the local git repository at runtime, so use values
      // embedded at build time by `make web-build` / `make web-deploy`.
      if (_webAppVersion.isNotEmpty) {
        appVersion = _webAppVersion;
      }
      if (_webBuildNumber.isNotEmpty) {
        buildNumber = _webBuildNumber;
      }
      if (_webCommitHash.isNotEmpty) {
        commitHash = _webCommitHash;
      }
      if (_webShortHash.isNotEmpty) {
        shortHash = _webShortHash;
      }
      if (_webBranch.isNotEmpty) {
        branch = _webBranch;
      }
      if (_webCommitDate.isNotEmpty) {
        commitDate = _webCommitDate;
      }
      hasGitInfo = shortHash != 'unknown' || commitHash != 'unknown';
    } else {
      try {
        // Get commit hash
        final hashResult = await Process.run(
          'git',
          ['rev-parse', 'HEAD'],
          runInShell: true,
        );
        if (hashResult.exitCode == 0) {
          commitHash = (hashResult.stdout as String).trim();
          hasGitInfo = true;
        }

        // Get short hash
        final shortHashResult = await Process.run(
          'git',
          ['rev-parse', '--short', 'HEAD'],
          runInShell: true,
        );
        if (shortHashResult.exitCode == 0) {
          shortHash = (shortHashResult.stdout as String).trim();
        }

        // Get branch
        final branchResult = await Process.run(
          'git',
          ['rev-parse', '--abbrev-ref', 'HEAD'],
          runInShell: true,
        );
        if (branchResult.exitCode == 0) {
          branch = (branchResult.stdout as String).trim();
        }

        // Get commit message
        final messageResult = await Process.run(
          'git',
          ['log', '-1', '--pretty=%B'],
          runInShell: true,
        );
        if (messageResult.exitCode == 0) {
          commitMessage = (messageResult.stdout as String).trim();
        }

        // Get commit date
        final dateResult = await Process.run(
          'git',
          ['log', '-1', '--format=%cd', '--date=iso'],
          runInShell: true,
        );
        if (dateResult.exitCode == 0) {
          commitDate = (dateResult.stdout as String).trim();
        }

        // Get commit author
        final authorResult = await Process.run(
          'git',
          ['log', '-1', '--pretty=%an'],
          runInShell: true,
        );
        if (authorResult.exitCode == 0) {
          commitAuthor = (authorResult.stdout as String).trim();
        }
      } catch (e) {
        debugPrint('Failed to get git info: $e');
        // Git info will remain as 'unknown'
      }
    }

    return VersionInfo(
      appVersion: appVersion,
      buildNumber: buildNumber,
      commitHash: commitHash,
      shortHash: shortHash,
      branch: branch,
      commitMessage: commitMessage,
      commitDate: commitDate,
      commitAuthor: commitAuthor,
      hasGitInfo: hasGitInfo,
    );
  }

  static Future<String> getVersionString() async {
    final info = await getVersionInfo();
    if (info.hasGitInfo) {
      return 'v${info.appVersion} (${info.buildNumber}) - ${info.shortHash}';
    }
    return 'v${info.appVersion} (${info.buildNumber})';
  }
}
