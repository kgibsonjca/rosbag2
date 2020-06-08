// Copyright 2018, Bosch Software Innovations GmbH.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef ROSBAG2_CPP__TYPES_HPP_
#define ROSBAG2_CPP__TYPES_HPP_

#include "rosbag2_cpp/types/introspection_message.hpp"

namespace rosbag2
{

struct StorageOptions
{
public:
  std::string uri;
  std::string storage_id;

  /**
   * The maximum size a bagfile can be, in bytes, before it is split.
   * A value of 0 indicates that bagfile splitting will not be used.
   */
  uint64_t max_bagfile_size =0;

  // The maximum duration a bagfile can be, in seconds, before it is split.
  // A value of 0 indicates that bagfile splitting will not be used.
  uint64_t max_bagfile_duration = 0;

};

}  // namespace rosbag2

#endif  // ROSBAG2_CPP__TYPES_HPP_
