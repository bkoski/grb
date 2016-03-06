// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function updateItemSort(item) {
  var targetId   = item.data('object-id');
  var entityType = item.data('entity-type');
  var anchor, anchorId;

  if(item.next('.' + entityType).length == 0) {
    anchor   = 'after';
    anchorId = item.prev('.' + entityType).data('object-id');
  } else {
    anchor   = 'before';
    anchorId = item.next('.' + entityType).data('object-id');
  }

  $.ajax("/" + entityType + "s/sort", {
    method: "PUT",
    data: { target_id: targetId, anchor: anchor, anchor_id: anchorId },
    error: function() { alert('Save failed!') },
    success: function() { console.log('ok.') }
  });  
}

function updateMilestoneStatus(milestone_name, status) {
  $.ajax("/milestones/" + milestone_name, {
    method: "PUT",
    data: { status: status },
    error: function() { alert('Save failed!') },
    success: function() { window.location.reload(true); }
  });  
}

$(document).ready(function() {
  $('.milestones').on('click', '.action', function(e) {
    var target = $(e.currentTarget);
    updateMilestoneStatus(target.closest('.milestone').find('.title').text(), target.data('status'));
  });
  $('.milestones').sortable({
    items: '.milestone',
    update: function(e, ui) { updateItemSort(ui.item); }
  });
});