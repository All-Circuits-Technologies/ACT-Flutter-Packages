// SPDX-FileCopyrightText: 2024 All Circuits Technologies <dev@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Test implementation to verify XML parsing without needing actual Azure connection
library test_xml_parsing;

import 'dart:io';

// Simple test to verify XML parsing logic
void main() {
  print('Testing Azure Blob Storage XML parsing logic...\n');

  // Sample XML response from Azure Blob Storage list operation
  const sampleXml = '''<?xml version="1.0" encoding="utf-8"?>
<EnumerationResults ServiceEndpoint="https://myaccount.blob.core.windows.net/" ContainerName="mycontainer">
  <Blobs>
    <Blob>
      <Name>mycontainer/file1.txt</Name>
      <Properties>
        <Last-Modified>Wed, 09 Sep 2009 09:20:02 GMT</Last-Modified>
        <Etag>0x8CBFF45D8A29A19</Etag>
        <Content-Length>100</Content-Length>
        <Content-Type>text/plain</Content-Type>
        <Content-Encoding />
        <Content-Language />
        <Content-MD5>3KpZl2TzuRf5P0zHWA==</Content-MD5>
        <Cache-Control />
        <BlobType>BlockBlob</BlobType>
        <LeaseStatus>unlocked</LeaseStatus>
        <LeaseState>available</LeaseState>
      </Properties>
    </Blob>
    <Blob>
      <Name>mycontainer/subdir/file2.txt</Name>
      <Properties>
        <Last-Modified>Wed, 09 Sep 2009 09:20:03 GMT</Last-Modified>
        <Etag>0x8CBFF45D8A29A20</Etag>
        <Content-Length>200</Content-Length>
        <Content-Type>text/plain</Content-Type>
        <BlobType>BlockBlob</BlobType>
        <LeaseStatus>unlocked</LeaseStatus>
        <LeaseState>available</LeaseState>
      </Properties>
    </Blob>
  </Blobs>
  <NextMarker />
</EnumerationResults>''';

  // Test the parsing logic
  final blobRegex = RegExp(r'<Blob>.*?</Blob>', dotAll: true);
  final nameRegex = RegExp(r'<Name>(.*?)</Name>');
  final lastModifiedRegex = RegExp(r'<Last-Modified>(.*?)</Last-Modified>');
  final contentLengthRegex = RegExp(r'<Content-Length>(\d+)</Content-Length>');
  final eTagRegex = RegExp(r'<Etag>(.*?)</Etag>');

  final blobMatches = blobRegex.allMatches(sampleXml);
  
  print('Found ${blobMatches.length} blobs in XML');
  
  int count = 0;
  for (final match in blobMatches) {
    count++;
    final blobXml = match.group(0)!;
    
    final nameMatch = nameRegex.firstMatch(blobXml);
    final lastModifiedMatch = lastModifiedRegex.firstMatch(blobXml);
    final contentLengthMatch = contentLengthRegex.firstMatch(blobXml);
    final eTagMatch = eTagRegex.firstMatch(blobXml);

    print('Blob $count:');
    print('  Name: ${nameMatch?.group(1)}');
    print('  Last Modified: ${lastModifiedMatch?.group(1)}');
    print('  Size: ${contentLengthMatch?.group(1)} bytes');
    print('  ETag: ${eTagMatch?.group(1)}');
    print();
  }

  // Test container prefix removal
  const containerName = 'mycontainer';
  final testName = 'mycontainer/file1.txt';
  
  String blobName = testName;
  if (blobName.startsWith('$containerName/')) {
    blobName = blobName.substring(containerName.length + 1);
  }
  
  print('Container prefix removal test:');
  print('  Original: $testName');
  print('  After removal: $blobName');
  print();

  // Test recursive vs non-recursive filtering
  const searchPath = '';
  const recursiveSearch = false;
  
  final testFiles = ['file1.txt', 'subdir/file2.txt'];
  
  print('Filtering test (searchPath="$searchPath", recursive=$recursiveSearch):');
  for (final fileName in testFiles) {
    bool shouldInclude = true;
    
    if (searchPath.isNotEmpty) {
      String normalizedSearchPath = searchPath.trim();
      if (normalizedSearchPath.startsWith('/')) {
        normalizedSearchPath = normalizedSearchPath.substring(1);
      }
      if (!normalizedSearchPath.endsWith('/') && normalizedSearchPath.isNotEmpty) {
        normalizedSearchPath = '$normalizedSearchPath/';
      }
      
      if (!fileName.startsWith(normalizedSearchPath)) {
        shouldInclude = false;
      } else if (!recursiveSearch) {
        final relativePath = fileName.substring(normalizedSearchPath.length);
        if (relativePath.contains('/')) {
          shouldInclude = false;
        }
      }
    } else if (!recursiveSearch) {
      if (fileName.contains('/')) {
        shouldInclude = false;
      }
    }
    
    print('  $fileName: ${shouldInclude ? "INCLUDE" : "EXCLUDE"}');
  }

  print('\n✅ XML parsing test completed successfully!');
}