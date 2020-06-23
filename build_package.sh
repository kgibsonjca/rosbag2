#!/bin/bash

mkdir -p '/home/jca/private_workspace/src'
PUBLIC_WORKSPACE='/home/jca/workspace'
MY_WORKSPACE='/home/jca/private_workspace'

cp -r ${PUBLIC_WORKSPACE}/* ${MY_WORKSPACE}

source "/opt/ros/$ROS_DISTRO/setup.bash"

cd ${MY_WORKSPACE}/src/

mkdir ${PUBLIC_WORKSPACE}/src/package/deploy
deploy_dir="${PUBLIC_WORKSPACE}/src/package/deploy"

# This method converts the Debian version to follow our internal label and build number guidelines
update_version ()
{
        # Checks for special branch names
        if [[ -z "${BRANCH_NAME}" ]];
        then
                LOCAL_BRANCH_NAME="orphan"
        elif [[ "${BRANCH_NAME}" == develop ]];
        then
                LOCAL_BRANCH_NAME="wip"
        elif [[ "${BRANCH_NAME}" == rc* ]];
        then
                LOCAL_BRANCH_NAME="rc"
        elif [[ "${BRANCH_NAME}" == hotfix* ]];
        then
                LOCAL_BRANCH_NAME="hotfix"
        else
                LOCAL_BRANCH_NAME=${BRANCH_NAME}
        fi

        if [[ "${LOCAL_BRANCH_NAME}" == master ]];
        then
                LOCAL_BRANCH_NAME=""
        elif [[ "${LOCAL_BRANCH_NAME}" != -* ]];
        then
                LOCAL_BRANCH_NAME=-${LOCAL_BRANCH_NAME}
        fi

        # Checks for build number and pads it
        if [[ -z "${BUILD_NUMBER}" ]];
        then
                BUILD_NUMBER="99999"
        fi
        PADDED_BUILD_NUMBER=`printf %05.0f $BUILD_NUMBER`

        # This uses a regex to grab the current version number from the ROS changelog
        IFS='-' read -ra ADDR <<< `cat debian/changelog | grep -oP '[0-9]+\.[0-9]+\.[0-9]+-[a-zA-Z0-9-_]+'`

        # Construct thenew version name
        new_version=${ADDR[0]}${LOCAL_BRANCH_NAME}+b${PADDED_BUILD_NUMBER}

        # Replaces current version number with the new version number
        sed -i -E "s/[0-9]+\.[0-9]+\.[0-9]+-[a-zA-Z0-9\-_]+/${new_version}/g" debian/changelog

}

# Builds the fake rosdep yaml file to allow for the conversion of ROS dependencies to Debian dependencies
build_rosdep ()
{
        # Clear the fake yaml file
        echo "" > /tmp/fake_rosdep.yaml

        # Convert exec_depends fields
        for rosdep in `cat package.xml | grep -oP "(?<=<exec_depend>)[^<]+"`
        do
                debdep=`echo "ros-melodic-${rosdep}" | tr _ -`
                echo "${rosdep}:
  ubuntu:
    apt:
      packages: [ ${debdep} ]" >> /tmp/fake_rosdep.yaml
        done

        # Convert depends fields
        for rosdep in `cat package.xml | grep -oP "(?<=<depend>)[^<]+"`
        do
                debdep=`echo "ros-melodic-${rosdep}" | tr _ -`
                echo "${rosdep}:
  ubuntu:
    apt:
      packages: [ ${debdep} ]" >> /tmp/fake_rosdep.yaml
        done

        # Trigger a rosdep update to bring in the faked out file
        rosdep update
}

# Builds the Debian package
build_package ()
{
        bloom-generate rosdebian
        update_version
        fakeroot debian/rules binary
        mv ../*.deb ${deploy_dir}
}

# Removes the debian and obj directories, needed for successive architecture builds
clean_package ()
{
        rm -rf debian
        rm -rf obj-*
}

# Search through subdirectories and checks for a package.xml and builds it
find_ros_packages ()
{
        root_dir=${PWD}

        for dir in ${PWD}/*
        do
                test -d "$dir"  || continue
                cd ${dir}
                echo "checking `pwd`"
                if [ -f package.xml ];
                then
                        echo "building package"
                        #build_rosdep
                        build_package
                        result=$?
                        clean_package
                        if (("${result}" > "0"));
                        then
                                echo "Build failed with "${result}" in "${dir}
                                exit 1
                        fi
                else
                        find_ros_packages
                fi

        done
        cd ${root_dir}

}

# Add fake yaml file for the ros dependencies
#echo "yaml file:///tmp/fake_rosdep.yaml" > /etc/ros/rosdep/sources.list.d/50-fake.list


#find_ros_packages

build_ros_package ()
{
        root_dir=${PWD}
        dir="$1"
        cd ${dir}
        echo "checking `pwd`"
        if [ -f package.xml ];
        then
                echo "building package"
                build_rosdep
                build_package
                result=$?
                clean_package
                if (("${result}" > "0"));
                then
                        echo "Build failed with "${result}" in "${dir}
                        exit 1
                fi
        else
                echo ${dir}" not a valid package!"
                exit 1
        fi

        cd ${root_dir}
}

ros-foxy-rosbag2-compression ros-foxy-rosbag2-converter-default-plugins ros-foxy-rosbag2-cpp ros-foxy-rosbag2-storage ros-foxy-rosbag2-storage-default-plugins ros-foxy-rosbag2-transport

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_test_common
dpkg --install ${deploy_dir}/*.deb


build_ros_package ${MY_WORKSPACE}/src/package/ros2bag

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2

build_ros_package  ${MY_WORKSPACE}/src/package/shared_queues_vendor

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_storage

dpkg --install ${deploy_dir}/*.deb

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_cpp

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_converter_default_plugins

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_storage_default_plugins


dpkg --install ${deploy_dir}/*.deb


build_ros_package  ${MY_WORKSPACE}/src/package/sqlite3_vendor

build_ros_package  ${MY_WORKSPACE}/src/package/zstd_vendor

dpkg --install ${deploy_dir}/*.deb

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_compression

dpkg --install ${deploy_dir}/*.deb

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_transport

dpkg --install ${deploy_dir}/*.deb

build_ros_package  ${MY_WORKSPACE}/src/package/rosbag2_tests

dpkg --install ${deploy_dir}/*.deb
