#!/usr/bin/env bash

# Rofi Wi-Fi Menu for Waybar (High-Contrast Icons)

# Rescan networks in the background
nmcli device wifi rescan 2>/dev/null &

# Get WiFi status
connected=$(nmcli -fields WIFI g | tail -n1 | xargs)
current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2-)

if [[ "$connected" == "enabled" ]]; then
    toggle="󰖪  Disable Wi-Fi"
elif [[ "$connected" == "disabled" ]]; then
    toggle="󰖩  Enable Wi-Fi"
    chosen=$(echo "$toggle" | rofi -dmenu -i -p "Wi-Fi")
    [[ "$chosen" == "$toggle" ]] && nmcli radio wifi on && notify-send "Wi-Fi" "Wi-Fi enabled"
    exit 0
fi

# Build network list with high-contrast signal & security icons
declare -a ssid_list
declare -A ssid_secured

wifi_list=""
while IFS='|' read -r ssid signal security; do
    [[ -z "$ssid" ]] && continue
    [[ -n "${ssid_secured[$ssid]+x}" ]] && continue

    ssid_secured["$ssid"]="$security"
    ssid_list+=("$ssid")

    # High-contrast lock icon
    if [[ -n "$security" && "$security" != "--" && "$security" != "" ]]; then
        lock_icon=""   # Solid Lock
    else
        lock_icon=""   # Open Unlocked
    fi

    # Signal strength icon
    if (( signal >= 75 )); then
        signal_icon="󰤨"
    elif (( signal >= 50 )); then
        signal_icon="󰤥"
    elif (( signal >= 25 )); then
        signal_icon="󰤢"
    else
        signal_icon="󰤟"
    fi

    # Connected status icon
    if [[ "$ssid" == "$current_ssid" ]]; then
        status_icon="󰄬"  # Checkmark
        wifi_list+="${status_icon}  ${signal_icon}  ${lock_icon}  ${ssid} (Connected)\n"
    else
        wifi_list+="   ${signal_icon}  ${lock_icon}  ${ssid}\n"
    fi
done < <(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | sed 's/\\:/COLON_PLACEHOLDER/g' | sort -t: -k2 -rn | while IFS=: read -r ssid signal security; do
    ssid=$(echo "$ssid" | sed 's/COLON_PLACEHOLDER/:/g')
    echo "${ssid}|${signal}|${security}"
done)

# Show main Rofi network picker
chosen=$(echo -e "$toggle\n󰤨  Rescan Networks\n$wifi_list" | sed '/^$/d' | rofi -dmenu -i -selected-row 1 -p "Wi-Fi")

# Handle selection
if [[ -z "$chosen" ]]; then
    exit 0
elif [[ "$chosen" == "󰖪  Disable Wi-Fi" ]]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Wi-Fi disabled"
elif [[ "$chosen" == "󰖩  Enable Wi-Fi" ]]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Wi-Fi enabled"
elif [[ "$chosen" == "󰤨  Rescan Networks" ]]; then
    nmcli device wifi rescan
    notify-send "Wi-Fi" "Rescanning networks..."
    sleep 2
    exec "$0"
else
    # Extract SSID (remove icons and status suffix)
    chosen_id=$(echo "$chosen" | sed -E 's/^([󰄬 ]{1,3})[ ]+[󰤨󰤥󰤢󰤟]+[ ]+[]+[ ]+//' | sed 's/ (Connected)$//')

    if [[ -z "$chosen_id" ]]; then
        exit 0
    fi

    # Disconnect if clicking current network
    if [[ "$chosen_id" == "$current_ssid" ]]; then
        disconnect=$(echo -e "No\nYes" | rofi -dmenu -i -p "Disconnect from $chosen_id?")
        if [[ "$disconnect" == "Yes" ]]; then
            nmcli connection down id "$chosen_id"
            notify-send "Wi-Fi" "Disconnected from \"$chosen_id\""
        fi
        exit 0
    fi

    notify-send "Wi-Fi" "Connecting to \"$chosen_id\"..."

    # Step 1: Try connecting directly if profile is already saved & valid
    conn_output=$(nmcli connection up id "$chosen_id" 2>&1)
    if echo "$conn_output" | grep -q "successfully activated"; then
        notify-send "Wi-Fi Connected" "Connected to \"$chosen_id\""
        exit 0
    fi

    # Step 2: Show clean Rofi Password Dialog Modal
    wifi_password=$(rofi -dmenu \
        -password \
        -mesg "Enter Password for: <b>$chosen_id</b>" \
        -theme-str '
            window { width: 400px; border-radius: 12px; padding: 15px; }
            mainbox { children: [ "message", "inputbar" ]; }
            message { padding: 5px 0px 10px 0px; }
            textbox { horizontal-align: 0.5; }
            inputbar { children: [ "entry" ]; padding: 10px; border-radius: 8px; }
            entry { placeholder: "Type Wi-Fi Password..."; horizontal-align: 0.5; }
            listview { enabled: false; }
        ')

    if [[ -z "$wifi_password" ]]; then
        notify-send "Wi-Fi" "Connection cancelled"
        exit 0
    fi

    # Connect with entered password
    connect_output=$(nmcli device wifi connect "$chosen_id" password "$wifi_password" 2>&1)

    if echo "$connect_output" | grep -q "successfully activated"; then
        notify-send "Wi-Fi Connected" "Connected to \"$chosen_id\""
    else
        # Cleanup corrupted profile on failure
        nmcli connection delete id "$chosen_id" 2>/dev/null
        notify-send "Wi-Fi Error" "Failed to connect. Wrong password for \"$chosen_id\"?"
    fi
fi
