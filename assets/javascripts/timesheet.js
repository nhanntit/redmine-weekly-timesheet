function CannotRemoveAlert() {
  alert("This issue is logged time so that you can't remove it from this grid");
}

function trim(stringToTrim) {
  return stringToTrim.replace(/^\s+|\s+$/g, "");
}

var hoursvalid = true;
function validateHours(id) {
  hoursvalid = false;
  var num = document.getElementById(id).value;
  if ((!isNaN(trim(num))) && !trim(num) == '' && !(num < 0))
    hoursvalid = true;
  return hoursvalid;
}

var daysvalid = true;
function validateDays(id) {
  daysvalid = false;
  var num = document.getElementById(id).value;
  if (!((isNaN(trim(num))) || trim(num) == '' || (num < 0) || !num.match(/^[0-9]+$/)))
    daysvalid = true;
  return daysvalid;
}

var textvalid = true;
function validateText(id) {
  textvalid = false;
  var text = document.getElementById(id).value;
  tlength = text.length
  if (tlength <= 255)
    textvalid = true;
  return textvalid;
}

function validateDate(id) {
  var dateString = document.getElementById(id).value;
  dateString = trim(dateString);
  document.getElementById(id).value = dateString;
  var re1 = /^\d{4}-\d{1,2}$/;
  var re2 = /^\d{1,2}$/;
  var re3 = /^\d{4}$/;
  if (dateString.search(re1) != -1 || dateString.search(re2) != -1 || dateString.search(re3) != -1) {
    if (dateString.length < 3) {
      if (dateString < 1 || dateString > 53) {
        alert("Please input week number with format yyyy-ww or ww(1-53).");
        return false;
      }
      else
        return true;
    }
    else if (dateString.length == 4) {
      if (dateString < 1900) {
        alert("Are you kidding?");
        return false;
      }
      else
        return true;
    }
    else {
      var date_array = dateString.split('-');
      if (date_array[1] < 1 || date_array[1] > 53) {
        alert("Please input week number with format yyyy-ww or ww (1-53).");
        return false;
      }
      if (date_array[0] < 1900) {
        alert("Are you kidding?");
        return false;
      }
      else
        return true;
    }
  }
  else {
    alert("Please input week number with format yyyy-ww or ww (1-53).")
    return false;
  }
}

function getElementLeft(Elem) {
  var elem;
  if (document.getElementById)
    var elem = document.getElementById(Elem);
  else if (document.all)
    var elem = document.all[Elem];
  xPos = elem.offsetLeft;
  tempEl = elem.offsetParent;
  while (tempEl != null) {
    xPos += tempEl.offsetLeft;
    tempEl = tempEl.offsetParent;
  }
  return xPos;
}

function getElementTop(Elem) {
  if (document.getElementById)
    var elem = document.getElementById(Elem);
  else if (document.all)
    var elem = document.all[Elem];
  yPos = elem.offsetTop;
  tempEl = elem.offsetParent;
  while (tempEl != null) {
    yPos += tempEl.offsetTop;
    tempEl = tempEl.offsetParent;
  }
  return yPos;
}

function showChooseDate(id, ids, project) {
  //alert(id)
  document.getElementById('popupChooseDate').style.top = getElementTop(id) + 'px'
  //alert(getElementTop(id))
  document.getElementById('popupChooseDate').style.left = getElementLeft(id) + 'px'
  document.getElementById('popupChooseDate').style.display = 'block';
  var date = getWeekNumber(new Date());
  document.getElementById('datetoadd').value = date[0] + '-' + date[1];
  document.getElementById('datetoadd').focus();
  document.getElementById('ids').value = ids;
  document.getElementById('project_id').value = project;
}

function showChooseDate_TS(id, ids, project, mode, current_time) {
  //alert(id)
  document.getElementById('popupChooseDate_TS').style.top = getElementTop(id) + 'px'
  //alert(getElementTop(id))
  document.getElementById('popupChooseDate_TS').style.left = getElementLeft(id) + 'px'
  document.getElementById('popupChooseDate_TS').style.display = 'block';
  var date = getWeekNumber(new Date());
  document.getElementById('datetoadd').value = date[0] + '-' + (date[1] + 1);
  document.getElementById('datetoadd').focus();
  document.getElementById('ids').value = ids;
  document.getElementById('tmode').value = mode;
  document.getElementById('ts_current_time').value = current_time;
  document.getElementById('project_id').value = project;
}

function showPopupLogtime(coordinate, date, issue, selected, ajax_method_url, mode, current_time) {
  $.ajax({
    url: ajax_method_url,
    data: {issue_id: issue, mode: mode, current_time: current_time},
    complete: function() {
      time_entry_activity_options = document.getElementById("time_entry_activity_id").getElementsByTagName("option");
      for (i = 0; i < time_entry_activity_options.length; i++)
        if (time_entry_activity_options[i].text == selected)
          time_entry_activity_options[i].selected = "selected";
      document.getElementById('popupLogtime').style.top = getElementTop(coordinate) + 17 + 'px'
      document.getElementById('popupLogtime').style.left = getElementLeft(coordinate) - 100 + 'px'
      document.getElementById('popupLogtime').style.display = 'block';
      document.getElementById('time_entry_comments').value = '';
      document.getElementById('time_entry_hours').value = '';
      document.getElementById('time_entry_hours').focus();
      document.getElementById('time_entry_spent_on').value = date;
      document.getElementById('time_entry_issue_id').value = issue;
      document.getElementById('back_url').value = document.URL;
    }
  });
}

function showPopupPlantime(coordinate, date, issue, comment, hours, effort_plan_id, tip_id) {
  //alert(comment);
  //alert(defectid);
  //alert(statusid);
//	if( !e ) e = window.event;
//	if( e.preventDefault )
//		e.preventDefault();
//	else
//		e.returnValue = false;
  newcomment = comment.replace(/&escape1/g, '\"')
  newcomment = newcomment.replace(/&escape2/g, "\'")
  hideTip(tip_id)
  document.getElementById('popupPlanTime').style.top = getElementTop(coordinate) + 17 + 'px'
  document.getElementById('popupPlanTime').style.left = getElementLeft(coordinate) - 100 + 'px'
  document.getElementById('popupPlanTime').style.display = 'block';
  document.getElementById('plan_comment').value = newcomment;
  document.getElementById('plan_hours').value = '';
  if (hours != 0)
    document.getElementById('plan_hours').value = hours;
  document.getElementById('plan_hours').focus();
  document.getElementById('plan_id').value = effort_plan_id;
  document.getElementById('plan_on').value = date;
  document.getElementById('issue_id').value = issue;
  document.getElementById('back_url').value = document.URL;
}

function check_repeate_efforts() {
  array = repeat_efforts.split(",");
  curr = current_day.split("-");
  num_days = document.getElementById('operators_repeat_status_id').value
  check = new Array();
  count = 0;
  curr_day = new Date();
  curr_day.setDate(curr[2]);
  curr_day.setMonth((curr[1] - 1));
  curr_day.setYear(curr[0]);

  for (var j = 1; j < num_days; j++) {
    curr_day.setDate(curr_day.getDate() + 1);
    if (curr_day.getDay() == 0 || curr_day.getDay() == 6) {
      num_days++;
      continue;
    }
    for (var i = 0; i < array.length; i++) {
      tempt = array[i].split("-");
      day2 = new Date();
      day2.setDate(tempt[2]);
      day2.setMonth(tempt[1] - 1);
      day2.setYear(tempt[0]);
      if (compare_date(curr_day, day2)) {
        check[count++] = array[i];
        break;
      }
    }
  }

  return check;
}

var repeat_efforts = "";
var current_day = "";
function init_data(efforts, current) {
  repeat_efforts = efforts;
  current_day = current;
}

function confirm_message() {
  check = check_repeate_efforts();
  check_box = document.getElementById('cb_repeat_status_id');
  num_days = document.getElementById('operators_repeat_status_id').value
  if (check.length > 0 && check_box.checked == true && num_days > 0) {
    conflict_days = "the date(s)( ";
    for (var i = 0; i < check.length; i++) {
      tempt = check[i].split("-");
      conflict_days += tempt[2] + "/" + tempt[1] + "/" + tempt[0];
      if (i < check.length - 1)
        conflict_days += ",";
    }
    conflict_days.slice(0, -2);
    answer = confirm(conflict_days + ") have been planned.\n Do you want to re-plan?");
    if (answer == false)
      return false;
    return true;
  }
  return true;
}

function compare_date(day1, day2) {
  if (day1.getDate() != day2.getDate())
    return false;
  if (day1.getMonth() != day2.getMonth())
    return false;
  if (day1.getFullYear() != day2.getFullYear())
    return false;
  return true;
}

function showTip(coordinate, id) {
  var it = document.getElementById(id);
  if (!it)
    return;
  document.getElementById(id).style.top = getElementTop(coordinate) + 17 + 'px'
  document.getElementById(id).style.left = getElementLeft(coordinate) - 100 + 'px'
  document.getElementById(id).style.display = 'block';
  //alert(id);
}

function hideTip(id) {
  var it = document.getElementById(id);
  if (!it)
    return;
  document.getElementById(id).style.display = 'none';

}

function toggleIssuesSelection(el) {
  var boxes = $(el).closest('table').find("input[name='ids[]']");
  var all_checked = true;
  for (i = 0; i < boxes.length; i++)
    if (boxes[i].checked == false) {
      all_checked = false;
      break;
    }
  for (i = 0; i < boxes.length; i++)
    if (all_checked) {
      boxes[i].checked = false;
      $(boxes[i]).closest('tr').removeClass('context-menu-selection');
    } else if (boxes[i].checked == false) {
      boxes[i].checked = true;
      $(boxes[i]).closest('tr').addClass('context-menu-selection');
    }
}

function removeAllNotice() {
  var notices = document.getElementsByClassName('flash');
  for (var i = 0; i < notices.length; ++i) {
    var notice = notices[i];
    notice.parentNode.removeChild(notice);
  }
}

// http://stackoverflow.com/questions/6117814/get-week-of-year-in-javascript-like-in-php
function getWeekNumber(d) {
  // Copy date so don't modify original
  d = new Date(+d);
  d.setHours(0,0,0);
  // Set to nearest Thursday: current date + 4 - current day number
  // Make Sunday's day number 7
  d.setDate(d.getDate() + 4 - (d.getDay()||7));
  // Get first day of year
  var yearStart = new Date(d.getFullYear(),0,1);
  // Calculate full weeks to nearest Thursday
  var weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7)
  // Return array of year and week number
  return [d.getFullYear(), weekNo];
}