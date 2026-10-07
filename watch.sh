#!/bin/bash
# Сторож. Ждёт новое уведомление Element и орёт сиреной, пока ты не ТРОНЕШЬ
# само сообщение, то есть пока триггернувшее уведомление не уйдёт из Центра
# уведомлений (клик по нему / открытие чата / смахивание). Просто открытый
# на экране Element больше не глушит.
DB="$HOME/Library/Group Containers/group.com.apple.usernoted/db2/db"
D="$HOME/mti/element-alarm"; LOG="$D/alarm.log"; STOP="$D/STOP"
S=/opt/homebrew/bin/SwitchAudioSource
MAXWAIT=1800   # страховочный предел сирены, 30 минут
log(){ echo "$(date '+%F %T') $*" >> "$LOG"; }

# есть ли ещё в базе запись с таким rec_id (0 = ушла, ты её тронул)
rec_present(){ [ "$(sqlite3 "$DB" "select count(*) from record where rec_id=$1;" 2>/dev/null)" != "0" ]; }

last=$(python3 "$D/detect.py" 0 2>/dev/null)
[ -z "$last" ] && { log "не могу читать базу уведомлений"; exit 1; }
log "сторож запущен, последний rec_id=$last"
rm -f "$STOP"

alarm(){
    local trig="$1"
    log "УВЕДОМЛЕНИЕ ELEMENT (rec_id=$trig), БУДИЛЬНИК — жду пока тронешь сообщение"
    $S -t output -s "Динамики MacBook Air" >/dev/null 2>&1
    local t0=$(date +%s)
    while :; do
        [ -f "$STOP" ] && { log "остановлен вручную (stop)"; break; }
        rec_present "$trig" || { log "уведомление тронуто (ушло из центра), глушу"; break; }
        [ $(( $(date +%s) - t0 )) -ge "$MAXWAIT" ] && { log "предел $((MAXWAIT/60)) мин, глушу сам"; break; }
        osascript -e 'set volume output volume 100' 2>/dev/null
        afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null
        afplay /System/Library/Sounds/Funk.aiff 2>/dev/null
    done
    rm -f "$STOP"
}

while :; do
    cur=$(python3 "$D/detect.py" "$last" 2>/dev/null)
    if [ -n "$cur" ] && [ "$cur" -gt "$last" ]; then
        trig=$cur; last=$cur
        alarm "$trig"
    fi
    sleep 4
done
