#!/bin/bash

#==================================
# 饥荒联机版服务器安装/管理脚本
#
# 请以root身份执行该脚本
# 推荐在Ubuntu操作系统上执行该脚本
#
# Author: SHIWIVI
# License: MIT
# Github仓库地址：https://github.com/shiwivi/dst-dst
#===================================

#--------------------
# 样式定义
#--------------------
RESET='\033[0m'
BOLD='\033[1m'
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'

#--------------------
# printf样式
#--------------------
# 提示信息
printf_info() { printf "%b\n" "${BLUE}$*${RESET}"; }
# 警告信息
printf_warning() { printf "%b\n" "${YELLOW}$*${RESET}"; }
# 错误信息
printf_error() { printf "%b\n" "${RED}$*${RESET}"; }
# 严重错误
fatal() {
  printf_error "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
  printf_error "脚本退出" >&2
  exit 1
}
# 手动暂停
pause() { read -rp "$*" _; }

#--------------------
# 全局变量
#--------------------
# 将以该用户身份启动steamCMD和游戏服务器
readonly USER_NAME="steam"
#steamCMD下载链接
#如果链接不可用，请参考Valve官方文档操作：https://developer.valvesoftware.com/wiki/Zh/SteamCMD#%E6%89%8B%E5%8A%A8%E5%AE%89%E8%A3%85
readonly STEAMCMD_URL="https://media.st.dl.bscstorage.net/client/installer/steamcmd_linux.tar.gz"
# steamCMD安装目录
readonly STEAMCMD_INSTALL_DIR="/home/${USER_NAME}/steamcmd"
# 饥荒安装目录
readonly DST_INSTALL_DIR="/home/${USER_NAME}/steamapps/DST"
# 饥荒游戏存档存放目录
readonly DST_DIR="/home/${USER_NAME}/klei/DST"
# 饥荒默认游戏存档名
cluster_name="Cluster_1"
# 游戏启动命令参数
klei_dir=$(dirname $DST_DIR)
conf_dir=$(basename $DST_DIR)

#-------------------
# 初始提示
#--------------------
hello_DST() {
  printf '%b\n' "${GREEN}==============================="
  printf '%s\n' "   饥荒联机版服务器搭建脚本"
  printf '%s\n' "      你是谁?你不是猪人"
  printf '%s\n' "        作者:SHIWIVI"
  printf '%s\n' "  开源许可协议(License):MIT"
  printf '%s\n' "Github仓库地址：https://github.com/shiwivi/dst-dst"
  printf '%b\n' "===============================${RESET}"
}

#--------------------
# 权限检查和用户创建
#--------------------
check_root() {
  if [ "$UID" -ne 0 ]; then
    printf_error "请以root权限执行该脚本"
    fatal "权限不足！"
  fi
}
create_user() {
  if ! id "${USER_NAME}" &>/dev/null; then
    printf_info "正在创建用户 ${USER_NAME}"
    useradd -m -s /bin/bash "${USER_NAME}"
  fi
  if [ ! -d "/home/${USER_NAME}" ]; then
    mkdir -p "/home/${USER_NAME}" # 避免已存在用户steam，但没有home目录
  fi
  chown -R "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}"
}
# 用户以root身份上传存档时修复权限，避免以steam身份无法访问
fix_permissions() {
  chown -R "$USER_NAME:$USER_NAME" "${klei_dir}" 2>/dev/null || true
}

#--------------------
# 文件检查
#--------------------
check_for_file() {
  printf '%s\n' "正在检查文件:$1"
  if [ ! -e "$1" ]; then
    fatal "文件${1}丢失"
  fi
}

#--------------------
# 安装 SteamCMD
#--------------------
install_from_url() {
  if [ -x "${STEAMCMD_INSTALL_DIR}/steamcmd.sh" ]; then
    return
  fi
  printf_info "正在安装依赖"
  if ! command -v curl &>/dev/null; then
    printf_info "安装curl工具..."
    if command -v apt &>/dev/null; then
      apt-get install -y curl
    elif command -v yum &>/dev/null; then
      yum install -y curl
    fi
  fi
  if command -v apt-get &>/dev/null; then
    printf_info "正在安装lib32gcc-sl"
    apt-get update
    apt-get install -y lib32gcc-s1
  elif command -v yum &>/dev/null; then
    printf_info "正在安装glibc.i686 libstdc++.i686"
    yum install -y glibc.i686 libstdc++.i686
  else
    fatal "不支持当前包管理器"
  fi

  mkdir -p "${STEAMCMD_INSTALL_DIR}"
  if curl -qLk --retry 3 --retry-delay 5 "${STEAMCMD_URL}" -o "${STEAMCMD_INSTALL_DIR}/steamcmd_linux.tar.gz"; then
    tar -C "${STEAMCMD_INSTALL_DIR}" -zxvf "${STEAMCMD_INSTALL_DIR}/steamcmd_linux.tar.gz"
    chown -R "${USER_NAME}:${USER_NAME}" "${STEAMCMD_INSTALL_DIR}"
    rm -f "${STEAMCMD_INSTALL_DIR}/steamcmd_linux.tar.gz"
  else
    fatal "下载失败，请检查网络"
  fi
}

#--------------------
# 安装游戏
#--------------------
install_DST() {
  if [ -f "$DST_INSTALL_DIR/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]; then
    printf_info "游戏似乎已经安装，是否继续尝试覆盖安装？[y确认][n取消]"
    read -r choice
    if [[ ! "$choice" =~ ^[yY]$ ]]; then
      printf_info "退出安装"
      return
    fi
  fi

  if [ -x "${STEAMCMD_INSTALL_DIR}/steamcmd.sh" ]; then
    sudo -u "${USER_NAME}" "${STEAMCMD_INSTALL_DIR}/steamcmd.sh" <<EOF
force_install_dir "${DST_INSTALL_DIR}"
login anonymous
app_update 343050 validate
quit
EOF
    if [ -f "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]; then
      mkdir -p "${DST_DIR}"
      printf_info "游戏安装完成!存档路径为:${DST_DIR}"
    else
      fatal "饥荒联机版安装失败，请稍后尝试重新安装"
    fi
  else
    fatal "未找到steamcmd文件，请检查steamcmd安装是否正确"
  fi

}

#--------------------
# 添加虚拟内存
#--------------------
set_swap() {
  # 交换文件大小,单位为GiB
  local swap_size=4
  # 交换文件路径
  local swap_file="/swap_by_dst"

  if [ -f "${swap_file}" ]; then
    printf_warning "似乎曾经通过该脚本添加过虚拟内存，是否重新添加？[y是][n否]"
    read -r choice
    if [[ $choice =~ ^[yY]$ ]]; then
      swapoff "${swap_file}" 2>/dev/null
      rm -f "${swap_file}"
      printf_info "已删除原有虚拟内存文件，将重新创建"
    else
      printf_info "退出设置虚拟内存"
      return
    fi
  fi

  # 查看当前内存、虚拟内存、剩余磁盘大小
  local total_memory=$(free -h | awk 'NR==2{print $2}')
  local total_swap=$(free -h | awk 'NR==3{print $2}')
  local avail_disk_size=$(df -k / | awk 'NR==2{printf "%d",$4/1024/1024}')

  printf "${BLUE}%s${RESET}\n" "==============="
  printf "%b\n" "${RED}当前服务器信息${RESET}"
  printf "${GREEN}总磁盘大小:${BLUE}%b${RESET}\n" "$(df -lh / | awk 'NR==2{print $2}')"
  printf "${GREEN}剩余磁盘大小:${BLUE}%b${RESET}\n" "${avail_disk_size}Gi"

  printf "${GREEN}总内存大小:${BLUE}%b${RESET}\n" "$(free -h | awk 'NR==2{print $2}')"
  printf "${GREEN}空闲内存大小:${BLUE}%b${RESET}\n" "$(free -h | awk 'NR==2{print $4}')"
  printf "${GREEN}虚拟内存大小:${BLUE}%b${RESET}\n" "$(free -h | awk 'NR==3{print $2}')"
  printf "${BLUE}%s${RESET}\n" "==============="

  while true; do
    printf_info "请输入要添加的虚拟内存大小(请输入整数,推荐2-8之间的值,单位为GiB,默认为4GiB)"
    read -r user_size

    if [ -n "$user_size" ]; then
      if [[ "$user_size" =~ ^[0-9]+$ ]]; then
        if [ "$user_size" -lt 1 ]; then
          printf_warning "输入值太小了"
          continue
        fi
        if [ "$user_size" -gt "${avail_disk_size}" ]; then
          printf_warning "输入值太了，超过了剩余磁盘大小，你完蛋了!"
          continue
        fi
        swap_size=$user_size
        break
      else
        printf_error "输入错误，退出虚拟内存配置"
        return 1
      fi
    else
      printf_info "使用默认值，即将设置为：${swap_size}GiB"
      break
    fi
  done

  # 优先尝试用fallocate创建交换文件，以节省时间
  # fallocate不可用时回退到dd命令
  if fallocate -l "${swap_size}" "${swap_file}"; then
    chmod 600 "${swap_file}"
    if ! mkswap "${swap_file}" 2>/dev/null; then
      printf_info "fallocate创建的文件不可用，正在修改为dd重建"
      rm -f "${swap_file}"

      dd if=/dev/zero of="${swap_file}" bs=1M count=$((swap_size * 1024)) status=progress
      chmod 600 "${swap_file}"
      mkswap "${swap_file}"
    fi
  else
    printf_info "fallocate不可用，正在通过dd创建"
    dd if=/dev/zero of="${swap_file}" bs=1M count=$((swap_size * 1024)) status=progress
    chmod 600 "${swap_file}"
    mkswap "${swap_file}"
  fi

  swapon "${swap_file}"

  if ! grep "${swap_file}" /etc/fstab; then
    echo "${swap_file} none swap sw 0 0" >>/etc/fstab
  fi
  printf_info "虚拟内存添加完毕"
}

#--------------------
# 世界管理
#--------------------
#查找世界
list_clusters() {
  local num=0
  cluster_arr=()

  for cluster in $(find ${DST_DIR} -mindepth 1 -maxdepth 1 -type d); do
    if [ -f "${cluster}/cluster.ini" ]; then
      cluster_arr+=("$cluster")
    fi
  done

  if [ "${#cluster_arr[@]}" -eq 0 ]; then
    printf_info "当前无任何世界存档"
    return 1
  fi

  printf "\t${RED}世界列表${RESET}\n"
  for cluster in "${cluster_arr[@]}"; do
    if [ -f "${cluster}/cluster.ini" ]; then
      num=$((num + 1))
      cluster_name=$(awk -F "=" '/cluster_name/{print $2}' "${cluster}/cluster.ini" | tr -d '\r\n')
      cluster_password=$(awk -F "=" '/cluster_password/{print $2}' "${cluster}/cluster.ini" | tr -d '\r\n')
      printf '%b\n' "${RED}-------------------${RESET}"
      printf "\t${YELLOW}世界%d${RESET}\n" $num
      printf "${GREEN}房间名: ${BLUE}%s${RESET}\n" "$cluster_name"
      printf "${GREEN}房间密码:${BLUE}%s${RESET}\n" "$cluster_password"
      printf "${GREEN}存档路径:${BLUE}%s${RESET}\n" "$cluster"
      printf '%b\n' "${RED}-------------------${RESET}"
    fi
  done
}

#备份世界
backup_cluster() {
  list_clusters

  if [ $? -eq 1 ]; then
    return
  fi

  while true; do
    printf_info "请输入要备份的世界编号:"
    read -r choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
      printf_error "无效的输入，即将退出备份"
      return
    fi
    if [ "$choice" -le ${#cluster_arr[@]} ] && [ "$choice" -gt 0 ]; then
      printf_info "${BLUE}正在备份世界${RESET}"
      cp -r "${cluster_arr[$((choice - 1))]}" "${cluster_arr[$((choice - 1))]}_backup"
      printf_info "世界已经备份到：${cluster_arr[$((choice - 1))]}_backup"
      break
    else
      printf_warning "无当前编号的世界，请重新输入"
    fi
  done
}

# 移除世界
remove_cluster() {
  list_clusters
  if [ $? -eq 1 ]; then
    pause "按任意键返回菜单...."
    return
  fi

  while true; do
    read -rp "请选择要删除的世界编号:" choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
      printf_error "无效的输入，即将退出删除"
      sleep 1
      return
    fi
    if [ "$choice" -le ${#cluster_arr[@]} ] && [ "$choice" -gt 0 ]; then
      break
    else
      printf_warning "无当前编号的世界，请重新输入"
    fi
  done

  local arr_index=$((choice - 1))
  local cluster_name=$(awk -F "=" '/cluster_name/{print $2}' "${cluster_arr[${arr_index}]}/cluster.ini" | tr -d '\r\n')
  printf '%b\n' "${RED}确定要删除世界\"${cluster_name}\"吗？[y确认][n取消]${RESET}"
  read -r rm_choice
  if [[ "$rm_choice" =~ ^[yY]$ ]]; then
    rm -rf "${cluster_arr[${arr_index}]}"
    printf_info '%s\n' "已移除世界${cluster_arr[${arr_index}]}"
  else
    printf_info '%s\n' "取消删除"
  fi
}

#--------------------
# 从存档提取模组ID并添加到dedicated_server_mods_setup.lua文件
#--------------------
load_mods() {
  printf_info "正在查找服务器模组"
  # 用户世界的模组配置文件
  local master_modoverrides="${cluster_arr[$1]}/Master/modoverrides.lua"
  # DST服务器模组下载文件
  local mods_setup_file="${DST_INSTALL_DIR}/mods/dedicated_server_mods_setup.lua"
  if [ -f "$master_modoverrides" ]; then
    for mod_ID in $(grep -o "workshop-[0-9]\+" "${master_modoverrides}" | sed 's/workshop-\([0-9]\+\)/ServerModSetup("\1")/'); do
      if ! grep "$mod_ID" "${mods_setup_file}" &>/dev/null; then
        printf_info "新增模组${mod_ID}"
        echo "$mod_ID" >>"${mods_setup_file}"
      fi
    done
  fi
}

#--------------------
# 查看服务器状态
#--------------------
check_game_status() {
  dst_pid_tmp="${klei_dir}/dst_pid_tmp.txt"
  dst_processes=()
  local index=0
  >"${dst_pid_tmp}"

  if [ -s "${klei_dir}/dst_pid.txt" ]; then
    while IFS= read -r line; do
      index=$((index + 1))
      local cluster_id=$(awk '{print $1}' <<<"${line}")
      local master_pid=$(awk '{print $2}' <<<"${line}")
      local caves_pid=$(awk '{print $3}' <<<"${line}")

      # 校验函数
      is_dst_process() {
        local cluster_id=$1
        local pid=$2

        [ -d "/proc/${pid}" ] &&
          grep -aqs "dontstarve_dedicated_server_nullrenderer" "/proc/${pid}/cmdline" &&
          grep -aqs "${cluster_id}" "/proc/${pid}/cmdline"
      }

      if is_dst_process "$cluster_id" "$master_pid"; then
        if [ -z "${caves_pid}" ]; then
          # 单地面世界
          dst_processes+=("${master_pid}")
          caves_pid="无"
          echo "${cluster_id} ${master_pid}" >>"${dst_pid_tmp}"
        elif is_dst_process "$cluster_id" "$caves_pid"; then
          #地面+洞穴
          dst_processes+=("${master_pid} ${caves_pid}")
          echo "${cluster_id} ${master_pid} ${caves_pid}" >>"${dst_pid_tmp}"
        else
          caves_pid="${RED}洞穴未能正常启动!${RESET}"
          echo "${cluster_id} ${master_pid}" >>"${dst_pid_tmp}"
        fi
      else
        master_pid="${RED}游戏未能正常启动${RESET}"
        caves_pid="${RED}游戏未能正常启动${RESET}"
      fi

      if [ -f "$DST_DIR/$cluster_id/cluster.ini" ]; then
        local cluster_name=$(awk -F "=" '/cluster_name/{print $2}' "${DST_DIR}/${cluster_id}/cluster.ini" | tr -d '\r\n')
        printf '%b\n' "${RED}-------------------${RESET}"
        printf "\t${YELLOW}世界%d${RESET}\n" "$index"
        printf "${GREEN}世界名: ${BLUE}%s${RESET}\n" "${cluster_name}"
        printf "${GREEN}master_pid(地面):${BLUE}%b${RESET}\n" "$master_pid"
        printf "${GREEN}caves_pid(洞穴):${BLUE}%b${RESET}\n" "${caves_pid}"
        printf "${GREEN}世界路径:${BLUE}%s${RESET}\n" "$DST_DIR/$cluster_id"
        printf '%b\n' "${RED}-------------------${RESET}"
      fi
    done <"${klei_dir}/dst_pid.txt"
    # 更新原有的dst_pid文件
    mv "${dst_pid_tmp}" "${klei_dir}/dst_pid.txt"
  else
    local ps_result=$(ps aux | grep "dontstarve_dedicated_server_nullrenderer" | sed '$d')
    if [ ! -z "$ps_result" ]; then
      printf '%b\n' "${RED}未能从脚本的配置文件找到在运行的服务器${RESET}"
      printf '%b\n' "${RED}但ps命令似乎有返回值：${RESET}"
      ps aux | grep "dontstarve_dedicated_server_nullrenderer" | sed '$d'
      return 1
    else
      printf '%b\n' "${RED}没有在运行的饥荒游戏服务器${RESET}"
      return 1
    fi

  fi

}

#--------------------
# 启动游戏
#--------------------
start_game() {
  list_clusters

  if [ $? -eq 1 ]; then
    return
  fi

  while true; do
    read -rp "请选择要启动的世界编号:" choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
      printf_error "无效的输入，启动失败，即将退出启动"
      sleep 1
      return
    fi
    if [ "$choice" -le ${#cluster_arr[@]} ] && [ "$choice" -gt 0 ]; then
      break
    else
      printf_warning "无当前编号的世界，请重新输入"
    fi
  done

  fix_permissions

  local arr_index=$((choice - 1))
  # 所启动世界的路径
  local current_cluster="${cluster_arr[${arr_index}]}"
  # 所启动世界的目录
  local cluster_dir=${current_cluster##*/}

  # 检查当前世界是否已经启动
  if grep "${cluster_dir}" "${klei_dir}/dst_pid.txt" > /dev/null 2>&1;then
    printf_error "$(awk -F '=' '/cluster_name/{print $2}' "${current_cluster}/cluster.ini" | tr -d ' \r\n')已经启动"
    printf_error "请根据以下结果检查否启动失败,如果失败,请尝试重新执行启动功能"
    check_game_status
    return
  fi

  # 是否启动洞穴
  local shard_enabled=$(awk -F "=" '/shard_enabled/{print $2}' "${DST_DIR}/${cluster_dir}/cluster.ini" | tr -d ' \t\n\r')

  # 添加当前存档modID
  load_mods "$arr_index"

  check_for_file "${DST_DIR}/${cluster_dir}/cluster.ini"
  check_for_file "${DST_DIR}/${cluster_dir}/cluster_token.txt"
  check_for_file "${DST_DIR}/${cluster_dir}/Master/server.ini"
  if [ -d "${DST_DIR}/${cluster_dir}/Caves" ]; then
    check_for_file "${DST_DIR}/${cluster_dir}/Caves/server.ini"
  fi
  check_for_file "$DST_INSTALL_DIR/bin64"

  sudo -u "$USER_NAME" "${STEAMCMD_INSTALL_DIR}/steamcmd.sh" +force_install_dir "$DST_INSTALL_DIR" +login anonymous +app_update 343050 +quit

  #启动游戏需要进入bin目录调用命令,不能使用绝对路径,否则游戏启动程序报错无法找到main.lua文件
  cd "${DST_INSTALL_DIR}/bin64" >/dev/null 2>&1 || fatal "无法切换到${DST_INSTALL_DIR}/bin64目录"

  run_shared=(./dontstarve_dedicated_server_nullrenderer_x64)
  run_shared+=(-console)
  run_shared+=(-persistent_storage_root "${klei_dir}")
  run_shared+=(-conf_dir "${conf_dir}")
  run_shared+=(-cluster "$cluster_dir")

  setsid sudo -u "$USER_NAME" "${run_shared[@]}" -shard Master >"${klei_dir}/master.log" 2>&1 &
  local dst_master_pid=$!

  local dst_caves_pid=""
  if [ "${shard_enabled}" = "true" ]; then
    setsid sudo -u "$USER_NAME" "${run_shared[@]}" -shard Caves >"${klei_dir}/caves.log" 2>&1 &
    dst_caves_pid=$!
  fi

  printf '%s\n' "${cluster_dir} ${dst_master_pid} ${dst_caves_pid}" >>"${klei_dir}/dst_pid.txt"
  tail -f "${klei_dir}/master.log"
}

#--------------------
# 关闭服务器
#--------------------
stop_game() {
  check_game_status
  if [ $? -eq 1 ]; then
    return
  fi
  printf '%b\n' "${BLUE}请输入世界编号来关闭指定世界,或输入a关闭所有世界:${RESET}"
  read -r choice
  if [[ "$choice" =~ ^[aA]$ ]]; then
    for process_record in "${dst_processes[@]}"; do
      kill -2 ${process_record}
    done
    >"${klei_dir}/dst_pid.txt"
    return
  fi

  if [[ ! "$choice" =~ ^[0-9]$ ]]; then
    printf_error "无效的输入"
    return 1
  fi

  if [ $choice -gt 0 ] && [ $choice -le "${#dst_processes[@]}" ]; then
    printf '%s\n' "正在关闭${dst_processes[$((choice - 1))]}"
    kill -2 ${dst_processes[$((choice - 1))]}
    sed -i "${choice}d" "${klei_dir}/dst_pid.txt"
  else
    printf_error "无效的输入"
    return 1
  fi
}

#--------------------
# 菜单交互
#--------------------
show_menu() {
  printf '%b\n' "${BLUE}*******************${RESET}"
  printf '%b\n' "${BLUE}功能列表:${RESET}"
  printf '%b\n' "${BOLD}1 安装游戏服务器${RESET}"
  printf '%b\n' "${BOLD}2 添加虚拟内存${RESET}"
  printf '%b\n' "${CYAN}3 启动游戏服务器"
  printf '%b\n' "4 查看服务器是否在运行"
  printf '%b\n' "5 关闭游戏服务器${RESET}"
  printf '%b\n' "${YELLOW}6 查看已有世界"
  printf '%b\n' "7 备份已有世界"
  printf '%b\n' "8 删除已有世界${RESET}"
  printf '%b\n' "${RED}9 退出脚本${RESEST}"
  printf '%b\n' "${BLUE}*******************${RESET}"
  printf '%b\n' "${BLUE}(如果输错，您随时可以ctrl+c强制终止脚本)${RESET}"
}

main() {
  tput clear
  hello_DST
  check_root
  while true; do
    show_menu
    printf '%b\n' "${GREEN}请输入功能编号:${RESET}"
    read -r choice
    case "$choice" in
    1)
      create_user
      install_from_url
      install_DST
      ;;
    2)
      set_swap
      pause "按任意键返回菜单..."
      ;;
    3)
      start_game
      pause "按任意键返回菜单..."
      ;;
    4)
      check_game_status
      pause "按任意键返回菜单..."
      ;;
    5)
      stop_game
      pause "按任意键返回菜单..."
      ;;
    6)
      list_clusters
      pause "按任意键返回菜单..."
      ;;
    7)
      backup_cluster
      pause "按任意键返回菜单...."
      ;;
    8) 
      remove_cluster
      pause "按任意键返回菜单...."
      ;;
    9)
      printf "%b\n" "${CYAN}查理会想你的${RESET}"
      exit 0
      ;;
    *)
      printf "%b\n" "${RED}错误的输入项，请重新输入${RESET}"
      sleep 1
      ;;
    esac
  done
}
main