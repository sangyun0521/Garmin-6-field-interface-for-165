using Toybox.Activity;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.UserProfile;
using Toybox.WatchUi;

class SixRunField extends WatchUi.DataField {
    // Activity.Info units: metres, metres/sec, milliseconds, beats/min.
    var values = ["0.00", "0:00", "0:00", "0:00", "0:00", "0"];
    var labels;
    var useOneFieldMessage;
    var labelFont = Graphics.FONT_XTINY;
    var heartFont = null;
    var hrZones = null;
    var currentHeartRate = null;
    var lapStartDistance = 0.0;
    var lapStartTime = 0;
    var lapKnown = false;
    var firstSample = true;
    var previousTime = null;
    var timerPaused = false;

    function initialize() {
        DataField.initialize();
        // 데이터 항목 이름
        labels = [
            WatchUi.loadResource(Rez.Strings.Distance),
            WatchUi.loadResource(Rez.Strings.AveragePace),
            WatchUi.loadResource(Rez.Strings.LapPace),
            WatchUi.loadResource(Rez.Strings.Pace),
            WatchUi.loadResource(Rez.Strings.ElapsedTime),
            WatchUi.loadResource(Rez.Strings.HeartRate)
        ];

        // 1개 필드가 아닌 경우 오류 메시지
        useOneFieldMessage = WatchUi.loadResource(Rez.Strings.UseOneField);

        // 데이터 항목 이름 크기 축소
        var smallerLabelFont = Graphics.getVectorFont({
            :font => Graphics.FONT_XTINY,
            :scale => 0.80
        });
        if (smallerLabelFont != null) { labelFont = smallerLabelFont; }
        heartFont = Graphics.getVectorFont({
            :face => "RobotoRegular",
            :size => 18
        });

        // 사용자 심박 존 정보 (심박수 색상 변경을 위해)
        loadHeartRateZones();
    }

    function loadHeartRateZones() {
        hrZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_RUNNING);
    }

    function resetLapVars() {
        lapStartDistance = 0.0;
        lapStartTime = 0;
        lapKnown = false;
        firstSample = true;
        previousTime = null;
    }

    function onTimerReset() {
        resetLapVars();
        timerPaused = false;
        values = ["0.00", "0:00", "0:00", "0:00", "0:00", "0"];
    }

    function onTimerStart() {
        timerPaused = false;
        loadHeartRateZones();
        lapStartDistance = 0.0;
        lapStartTime = 0;
        lapKnown = true;
        firstSample = false;
    }

    function onTimerResume() {
        timerPaused = false;
    }

    function onTimerPause() {
        timerPaused = true;
    }

    function onTimerStop() {
        timerPaused = true;
    }

    function onTimerLap() {
        var info = Activity.getActivityInfo();
        if (info != null && info.elapsedDistance != null && info.timerTime != null) {
            lapStartDistance = info.elapsedDistance;
            lapStartTime = info.timerTime;
            lapKnown = true;
            firstSample = false;
        } else {
            lapKnown = false;
        }
        values[2] = "0:00";
    }
    
    // speed(m/s) to pace
    function pace(speed) {
        if (speed == null) { return "--:--"; }
        if (speed <= 0) { return "0:00"; }

        // 1K / speed = pace
        var seconds = Math.floor(1000.0 / speed + 0.5).toNumber();

        // 59:59면 멈춘걸로.
        if (seconds > 3599) { return "0:00"; }
        var minutes = (seconds / 60).toNumber();
    
        return minutes.format("%d") + ":" + (seconds % 60).format("%02d");
    }

    // lap pace
    function lapSpeed(dist, time) {
        // dist : 전체 dist
        // time : 전체 time
        if (lapKnown && dist != null && time != null) {
            // 현재 랩 거리
            var currentLapDistance = dist - lapStartDistance;
            var currentLapTimeMs = time - lapStartTime;
            if (currentLapDistance > 0 && currentLapTimeMs > 0) {
                return currentLapDistance / (currentLapTimeMs / 1000.0);
            }
        }

        return null;
    }

    // ms to min:sec
    function duration(ms) {
        if (ms == null || ms < 0) { return "0:00"; }

        var total = Math.floor(ms / 1000.0).toNumber();
        var hours = (total / 3600).toNumber();
        var minutes = ((total % 3600) / 60).toNumber();
        var seconds = total % 60;

        if (hours > 0) {
            return hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        }

        return minutes.format("%d") + ":" + seconds.format("%02d");
    }

    // m to km
    function distance(meters) {
        if (meters == null || meters < 0) { return "--"; }
        // Convert metres to hundredths of a kilometre and round once.
        // Building the decimal string explicitly avoids device-specific
        // floating-point formatting differences.
        var hundredths = Math.floor(meters / 10.0 + 0.5).toNumber();
        var kilometres = (hundredths / 100).toNumber();
    
        return kilometres.format("%d") + "." + (hundredths % 100).format("%02d");
    }
    
    function heartRate(hr) {
        if (hr == null || hr <= 0) { return "--"; }

        return hr.format("%d");
    }

    // 현재 심박 존을 0(Zone 1)부터 4(Zone 5)까지 반환한다.
    function heartRateZone(heartRate) {
        if (heartRate == null || heartRate <= 0) {
            return -1;
        }

        if (hrZones == null || hrZones.size() < 6 ||
            hrZones[1] <= 0 || hrZones[1] >= hrZones[2] ||
            hrZones[2] >= hrZones[3] || hrZones[3] >= hrZones[4]) {
            return -1;
        }

        if (heartRate <= hrZones[1]) { return 0; }
        if (heartRate <= hrZones[2]) { return 1; }
        if (heartRate <= hrZones[3]) { return 2; }
        if (heartRate <= hrZones[4]) { return 3; }
        return 4;
    }

    function drawHeart(dc, centerX, centerY) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        if (heartFont != null) {
            dc.drawText(centerX, centerY - dc.getFontHeight(heartFont) / 2,
                heartFont, "♥", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        dc.fillCircle(centerX - 3, centerY - 2, 4);
        dc.fillCircle(centerX + 3, centerY - 2, 4);
        dc.fillPolygon([
            [centerX - 7, centerY - 1],
            [centerX + 7, centerY - 1],
            [centerX, centerY + 8]
        ]);
    }

    function drawHeartRateZones(dc, centerX, centerY, radius) {
        dc.setAntiAlias(true);

        var colors = [
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_BLUE,
            Graphics.COLOR_GREEN,
            Graphics.COLOR_ORANGE,
            Graphics.COLOR_RED
        ];
        var currentZone = heartRateZone(currentHeartRate);
        var segmentDegrees = 20;
        var gapDegrees = 0;
        var firstAngle = 220;
        for (var i = 0; i < 5; i += 1) {
            var selected = i == currentZone;
            var startAngle = firstAngle + i * (segmentDegrees + gapDegrees);
            dc.setColor(colors[i], Graphics.COLOR_BLACK);
            dc.setPenWidth(selected ? 6 : 3);
            dc.drawArc(centerX, centerY, radius,
                Graphics.ARC_COUNTER_CLOCKWISE, startAngle, startAngle + segmentDegrees);
        }

        // 현재 심박수가 해당 존 안에서 차지하는 비율을 흰색 막대로 표시한다.
        if (currentZone >= 0) {
            var zoneMin = hrZones[currentZone];
            var zoneMax = hrZones[currentZone + 1];
            var zoneRatio = (currentHeartRate - zoneMin).toFloat() / (zoneMax - zoneMin);
            if (zoneRatio < 0) { zoneRatio = 0.0; }
            if (zoneRatio > 1) { zoneRatio = 1.0; }

            var markerAngle = firstAngle +
                currentZone * (segmentDegrees + gapDegrees) +
                segmentDegrees * zoneRatio;
            var radians = Math.toRadians(markerAngle);
            var innerRadius = radius - 7;
            var outerRadius = radius + 7;
            var innerX = Math.round(centerX + Math.cos(radians) * innerRadius);
            var innerY = Math.round(centerY - Math.sin(radians) * innerRadius);
            var outerX = Math.round(centerX + Math.cos(radians) * outerRadius);
            var outerY = Math.round(centerY - Math.sin(radians) * outerRadius);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.setPenWidth(4);
            dc.drawLine(innerX, innerY, outerX, outerY);
        }
        dc.setPenWidth(1);
    }

    // Garmin이 1초마다 호출
    function compute(info) {
        // 일시정지 중에는 심박수만 변경
        if (timerPaused) { 
            currentHeartRate = info.currentHeartRate;
            values[5] = heartRate(currentHeartRate);
            return;
        }

        // lap 처리
        if (info.timerTime != null && previousTime != null && info.timerTime < previousTime) {
            resetLapVars();
        }

        // 운동 중 데이터 필드를 설정하는 경우 랩 페이스는 부정확하다.
        if (firstSample && info.timerTime != null && info.elapsedDistance != null) {
            // compute가 단순히 조금 늦게 호출 되었을 수 도 있다.
            lapKnown = (info.timerTime <= 1500 && info.elapsedDistance <= 20);
            firstSample = false;
        }

        // lap 처리를 위해 prevTime 계산
        if (info.timerTime != null) { previousTime = info.timerTime; }

        // 데이터 필드 값 계산
        values[0] = distance(info.elapsedDistance);
        values[1] = pace(info.averageSpeed);
        values[2] = pace(lapSpeed(info.elapsedDistance, info.timerTime));
        values[3] = pace(info.currentSpeed);
        values[4] = duration(info.timerTime);
        currentHeartRate = info.currentHeartRate;
        values[5] = heartRate(currentHeartRate);
    }

    function drawCell(dc, index, cx, cy, width) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(cx, cy - 33, labelFont, labels[index], Graphics.TEXT_JUSTIFY_CENTER);
        var fonts = index == 0
            ? [Graphics.FONT_SYSTEM_LARGE, Graphics.FONT_SYSTEM_MEDIUM, Graphics.FONT_SYSTEM_SMALL, Graphics.FONT_SYSTEM_TINY]
            : [Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_XTINY];
        var font = fonts[fonts.size() - 1];
        for (var i = 0; i < fonts.size(); i += 1) {
            if (dc.getTextWidthInPixels(values[index], fonts[i]) <= width && dc.getFontHeight(fonts[i]) <= 50) {
                font = fonts[i];
                break;
            }
        }
        var valueColor = Graphics.COLOR_WHITE;
        var valueY = cy - 33 + dc.getFontHeight(labelFont) + 2;
        if (index == 5) {
            var heartWidth = 14;
            var heartGap = 6;
            var textWidth = dc.getTextWidthInPixels(values[index], font);
            // 숫자는 화면 중앙에 두고, 하트만 숫자의 왼쪽에 배치한다.
            var heartX = cx - textWidth / 2 - heartGap - heartWidth / 2;
            var heartY = valueY + dc.getFontHeight(font) / 2 - 2;
            drawHeart(dc, heartX, heartY);
        }
        dc.setColor(valueColor, Graphics.COLOR_BLACK);
        dc.drawText(cx, valueY, font, values[index], Graphics.TEXT_JUSTIFY_CENTER);
        if (index == 5) {
            // 선 두께가 화면 밖으로 잘리지 않을 정도의 여백만 남긴다.
            drawHeartRateZones(dc, dc.getWidth() / 2, dc.getHeight() / 2, dc.getWidth() / 2 - 10);
        }
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if (w < 300 || h < 300) {
            dc.drawText(w / 2, h / 2 - dc.getFontHeight(Graphics.FONT_XTINY) / 2,
                Graphics.FONT_XTINY, useOneFieldMessage, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        // Full-width distance and HR caps; four middle cells.
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine(w * 0.07, h * 0.28, w * 0.93, h * 0.28);
        dc.drawLine(w * 0.02, h * 0.50, w * 0.98, h * 0.50);
        dc.drawLine(w * 0.07, h * 0.72, w * 0.93, h * 0.72);
        dc.drawLine(w / 2, h * 0.28, w / 2, h * 0.72);
        drawCell(dc, 0, w * 0.50, h * 0.16, w * 0.48);
        drawCell(dc, 1, w * 0.26, h * 0.39, w * 0.40);
        drawCell(dc, 2, w * 0.74, h * 0.39, w * 0.40);
        drawCell(dc, 4, w * 0.26, h * 0.61, w * 0.40);
        drawCell(dc, 3, w * 0.74, h * 0.61, w * 0.40);
        drawCell(dc, 5, w * 0.50, h * 0.84, w * 0.44);
    }
}
