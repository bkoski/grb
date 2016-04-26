Pusher.log = function(message) {
  if (window.console && window.console.log) {
    window.console.log(message);
  }
};


function IssuesCollection(issues) {

  this.issues = {};
  var that = this;
  _.each(issues, function(i) { that.issues[i._id] = i; })

  this.updateCallbacks = [];
  this.masterFilter    = function() { return true; };

  this.pusher = new Pusher('57023099609bcbe99e63', {
      encrypted: true
  });
  this.pusherChannel = this.pusher.subscribe('grb');

  this.registerForUpdates = function(callback) {
    this.updateCallbacks.push(callback)
  }

  this.registerRenderer = function(opts) {
    this.registerForUpdates(function(issues) {
      var matching_issues = _.filter(issues, opts.filter);
      matching_issues = _.sortBy(matching_issues, function(issue) { return issue.sort_order });

      var new_html = _.map(matching_issues, function(issue) { return JST['templates/' + opts.template_name](_.extend(issue, { opts: opts.template_opts })); }).join('');
      $(opts.target_el).html(new_html);

      if(matching_issues.length == 0) {
        console.log(opts.target_el)
        $(opts.target_el).closest('.grouping').hide();
      } else {
        $(opts.target_el).closest('.grouping').show();        
      }

    });
  }

  this.triggerUpdate = function() {
    var filteredIssues = _.filter(_.values(this.issues), this.masterFilter);
    _.each(this.updateCallbacks, function(cb) {
      cb(filteredIssues);
    });
  }

  this.pusherChannel.bind('update', function(data) {
    that.issues[data._id] = data;
    that.triggerUpdate();
  });

}