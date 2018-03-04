class MainItem {
  MainItem(this.title, this.description, {this.route});
  String title;
  String description;
  String route;
}

class MainRouteItem {
  MainRouteItem(this.title, this.description, {this.route});
  String title;
  String description;
  MainRouteItem route;
}
