# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all C++ sources for the dart:builtin library and
# some of the C++ sources for the dart:io library.  The rest are in
# io_impl_sources.gypi.
{
  'sources': [
    'io_buffer.cc',
    'io_buffer.h',
    'dartutils.cc',
    'dartutils.h',
    'dbg_connection.cc',
    'dbg_connection.h',
    'dbg_connection_android.cc',
    'dbg_connection_linux.cc',
    'dbg_connection_linux.h',
    'dbg_connection_macos.cc',
    'dbg_connection_macos.h',
    'dbg_connection_win.cc',
    'dbg_connection_win.h',
    'dbg_message.h',
    'dbg_message.cc',
    'directory.cc',
    'directory.h',
    'directory_android.cc',
    'directory_linux.cc',
    'directory_macos.cc',
    'directory_win.cc',
    'extensions.h',
    'extensions.cc',
    'extensions_android.cc',
    'extensions_linux.cc',
    'extensions_macos.cc',
    'extensions_win.cc',
    'file.cc',
    'file.h',
    'file_android.cc',
    'file_linux.cc',
    'file_macos.cc',
    'file_win.cc',
    'file_test.cc',
    'file_system_watcher.cc',
    'file_system_watcher.h',
    'file_system_watcher_android.cc',
    'file_system_watcher_linux.cc',
    'file_system_watcher_macos.cc',
    'file_system_watcher_win.cc',
    'fdutils.h',
    'fdutils_android.cc',
    'fdutils_linux.cc',
    'fdutils_macos.cc',
    'hashmap_test.cc',
    'isolate_data.h',
    'signal_blocker.h',
    'thread.h',
    'utils.h',
    'utils_android.cc',
    'utils_linux.cc',
    'utils_macos.cc',
    'utils_win.cc',
    'utils_win.h',
  ],
}
