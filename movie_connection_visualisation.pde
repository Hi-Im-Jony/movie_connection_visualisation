
  import java.util.stream.Collectors;
  import java.util.*;

  int startingY = 700;
  int startingX = 600;

  int num_movies = 120;
  color female = color(255,192,203);
  color male = color(50, 100, 150);

  TableRow selectedMovie;

  Table movies_table;
  HashMap<String, Node> movie_nodes = new HashMap();
  HashMap<String, Node> actor_nodes = new HashMap();
  HashMap<String, Node> director_nodes = new HashMap();
  HashMap<String, Integer> companyColors = new HashMap();
  HashMap<String, Integer> takenDates = new HashMap();
  LinkedHashMap<String, Node> sortedMovies = new LinkedHashMap<>();

  Integer minYear = 1980;
  Integer maxYear = Integer.MIN_VALUE;
  float highestRevenue = 0;
  float lowestRevenue = float(Integer.MAX_VALUE);
  int gridSize = 5;

  void setup() {
    randomSeed(42);
    size(1920, 1080);
    loadData(); 
    println("Preparing nodes...");
    prepareNodes();
    prepareScatterNodes();
    positionActors();
    println("Done Setup");
  }

  void loadData() {
  takenDates = new HashMap();
  movies_table = loadTable("movies.csv", "header");
  movies_table.clearRows();
  Table secondTable = loadTable("movies.csv", "header");
  // Initialize the HashMap for production company colors
  companyColors = new HashMap<String, Integer>();
  int i = 0;
  for (TableRow row : secondTable.rows()) {
    String[] dateParts = row.getString("release_date").split("/");
    int year = Integer.parseInt(dateParts[2]);
    int month = Integer.parseInt(dateParts[0]);
    String key = year + "/" + month;
    if ((!takenDates.containsKey(key)) && year > minYear) {
      takenDates.put(key, 0);
      movies_table.addRow(row);
      String company = row.getString("production_companies").split(",")[0]; // Get the first company
      if (!companyColors.containsKey(company)) {
        companyColors.put(company, color(random(255), random(255), random(255))); // Assign a random color
      }
    } 
    maxYear = max(maxYear, year);
  }
  println(movies_table.getRowCount() + "unique date movies");
}
void sortColumn(Table table, String column) {
  
}

  // movie_id,budget,genres,overview,production_companies,release_date,revenue,vote_average,title,cast,crew,actors,directors
  void prepareNodes() {
    sortColumn(movies_table, "budget");
    movies_table.sort("budget");
    println("Highest budget: " + movies_table.getRow(2).getFloat("budget"));
    println("Lowest budget: " + movies_table.getRow(10).getFloat("budget"));
    for (TableRow row : movies_table.rows()) {
      row.setFloat("budget", row.getFloat("budget") + 1.0E8);
      // color and size
      // color c = companyColors.get(
      //   row.getString("production_companies").
      //   split(",")[0]);
      // color c = color(50, 100, 100);
      color c = lerpColor(color(255,0,0), color(0,255,0), map((row.getFloat("vote_average")), 3, 10, 0, 1));
      // position x,y
      String[] dateParts = row.getString("release_date").split("/");
      int year = Integer.parseInt(dateParts[2]);
      int month = Integer.parseInt(dateParts[0]);
      String key = year + "/" + month;
      float z = int(random(-12, -1)) * 25; 
      // Node movieNode = new Node("mov", row.getString("title"), c, size*1, new PVector(width/5 + month*gridSize*6 + (year-minYear)*15, height - height*0.45 - (year - minYear)*gridSize*1.2, 0));
      Node movieNode = new Node("mov", row.getString("title"), c, 10, new PVector(width/15 + (year-minYear)*gridSize*6 + (month-1)*((gridSize*6)/12), height - height*0.65 + month*gridSize*2.5, 0));

      JSONArray actors = parseJSONArray(row.getString("actors"));
      JSONArray directors = parseJSONArray(row.getString("directors"));

      actor_nodes = makeConnections(actors, "act", movieNode);
      // director_nodes = makeConnections(directors, "dir", movieNode);
      movie_nodes.put(key, movieNode);    

      lowestRevenue = lowestRevenue < row.getFloat("revenue")/row.getFloat("budget") ? lowestRevenue : row.getFloat("revenue")/row.getFloat("budget");
      highestRevenue = highestRevenue > row.getFloat("revenue")/row.getFloat("budget") ? highestRevenue : row.getFloat("revenue")/row.getFloat("budget");
    }
    movies_table.sort("budget");
   for (TableRow row : movies_table.rows()) {
     row.setFloat("budget", row.getFloat("budget") - 1.0E8);
   }

  List<Map.Entry<String, Node>> entries = new ArrayList<>(movie_nodes.entrySet());
  Collections.sort(entries, (e2, e1) -> Float.compare(e1.getValue().size, e2.getValue().size));
  for (Map.Entry<String, Node> entry : entries) {
            sortedMovies.put(entry.getKey(), entry.getValue());
  }

 }

void positionActors() {
    for (Node actor : actor_nodes.values()) {
      actor.position.x = random(width/15, width*2/3);
      actor.position.y = random(height*0.05, height*0.25);
    }
}

HashMap<String, Node> makeConnections(JSONArray people, String personType, Node movieNode) {
  HashMap<String, Integer> donePeoplePairs = new HashMap<String, Integer>();
  HashMap<String, Node> nodes = personType.equals("act") ? actor_nodes : director_nodes;
  // add movie-actor and actor-actor connections
  for (int i = 0; i < people.size(); i++) {
    JSONObject person = people.getJSONObject(i);
    String name = person.getString("name");
    Node n;
    if (nodes.containsKey(name)) {
      n = nodes.get(name);
      n.size++; // size == num movies in
    } else {
      n = new Node(personType, name, (person.getInt("gender")==2) ? male : female, 1, new PVector(startingX, -startingY, 0));
    }
    movieNode.addConnection(n);
    n.addCopyConnection(movieNode);
    for (int j = 0; j < people.size(); j++) {
      JSONObject actor2 = people.getJSONObject(j);
      String name2 = actor2.getString("name");
      if (!name.equals(name2)) {
        Node n2;
        if (nodes.containsKey(name2)) {
          n2 = nodes.get(name2);
        } else {
          n2 = new Node(personType, name2, (person.getInt("gender")==2) ? male : female, 0, new PVector(startingX, -startingY, 0));
        }
        // pick 'main' node alphabetically
        int res = name.compareTo(name2);
        Node tmp;
        if (res > 0) {
          tmp = n;
          n = n2;
          n2 = tmp;
        }

        // add connection 
        if (!donePeoplePairs.containsKey(n.name + n2.name)) {
          n.addConnection(n2);
          n2.addCopyConnection(n);
          donePeoplePairs.put((n.name + n2.name), 0);
        }
        nodes.put(n2.name, n2);
      }
    }   
    nodes.put(n.name, n);
  }
  return nodes;
}

void draw() {
  background(250);
  mouseMoved();
  drawConnections(); 
  drawNodes();
  drawBackground();
  drawScatterPlot();
  drawOverview();
  drawLegends();
  
}

void drawNodes() {
  // movies
  for (Node node : sortedMovies.values()) {
    if (node.visible) {
      stroke(1);
      strokeWeight(1);
    } else {
      noStroke();
    }
    fill(node.c, (node.visible) ? 255 : 25);
    pushMatrix();
    circle(node.position.x, node.position.y, node.size);
    popMatrix();
  }
  // actors
  for (Node node : actor_nodes.values()) {
    // node.visible = node.size > 16;
    if (node.visible) {
      stroke(1);
      strokeWeight(2);
    } else {
      noStroke();
    }
    fill(node.c, (node.visible) ? 255 : 25);
    pushMatrix();
    circle(node.position.x, node.position.y, 5 + node.size * 5);
    popMatrix();
  }
  // scatter plot
  for (Node node : scatterNodes.values()) {
    if (node.visible) {
      stroke(1);
      strokeWeight(1);
    } else {
      noStroke();
    }
    fill(node.c, (node.visible) ? 255 : 25);
    pushMatrix();
    circle(node.position.x, node.position.y, node.size);
    popMatrix();
  }
}

void drawConnections() {
  float middleX = (width/15 + width*2/3) / 2;
  float middleY = height * 0.27;
  noFill();
  strokeWeight(0.2);
  stroke(0, 25);
  for (Node m : movie_nodes.values()) {
    if (m.visible) {
      
      stroke(0,m.selected ? 255 : 25);
      
      for (Node a : m.connections.keySet()) {
        a = actor_nodes.get(a.name);
        beginShape();
        vertex(a.position.x, a.position.y);
        bezierVertex(a.position.x, middleY, middleX, middleY, middleX, height * 0.30);
        endShape();
      }
      stroke(0, 255);
      beginShape();
      vertex(middleX, height * 0.30);
      bezierVertex(middleX, height * 0.33, m.position.x, height * 0.33, m.position.x, m.position.y);
      endShape();

    }
  }
}

boolean anyOverlap;
void mouseMoved() {
  for (Node a : actor_nodes.values()) {
        a.visible = false;
      }
  anyOverlap = false;
  for (Node movieNode : movie_nodes.values()) {
    movieNode.visible = false;
    float dx = mouseX - movieNode.position.x;
    float dy = mouseY- movieNode.position.y;
    float distance = (float) Math.sqrt(dx * dx + dy * dy);
    boolean mouseOverlaps = distance <= (movieNode.size/2);
    if (mouseOverlaps) {
      anyOverlap = true;
      movieNode.visible = true;
      movieNode.selected = true;
      selectedMovie = movies_table.findRow(movieNode.name, "title");
      for (Node a : actor_nodes.values()) {
        a.visible = movieNode.connections.containsKey(a);
      }
      for (Node s : scatterNodes.values()) {
        s.visible = movieNode.name.equals(s.name);
      }
    }
  }
  for (Node s : scatterNodes.values()) {
    s.visible = false;
    float dx = mouseX - s.position.x;
    float dy = mouseY- s.position.y;
    float distance = (float) Math.sqrt(dx * dx + dy * dy);
    boolean mouseOverlaps = distance <= (s.size/2);
    if (mouseOverlaps) {
      anyOverlap = true;
      s.visible = true;
      s.selected = true;
      selectedMovie = movies_table.findRow(s.name, "title");
      
      for (Node m : movie_nodes.values()) {
        if(m.name.equals(s.name)) {
          m.visible = true;
          m.selected = true;
          for (Node a : actor_nodes.values()) {
           a.visible = m.connections.containsKey(a) || a.visible;
          }
        }
      }
    } else {
      for (Node m : movie_nodes.values()) {
        if(m.name.equals(s.name) && m.visible) {
          s.visible = true;
        }
      }
    }
  }
  if (!anyOverlap) {
    for (Node movieNode : movie_nodes.values()) {
      movieNode.visible = true;
      movieNode.selected = false;
    }
    for (Node a : actor_nodes.values()) {
      a.visible = true;
      a.selected = false;
    }
    for (Node s : scatterNodes.values()) {
      s.visible = true;
      s.selected = false;
    }
  }
}

HashMap<String, Node> scatterNodes = new HashMap();
void prepareScatterNodes() {
  float baseHeight = height*0.8;
  float yAxisLength = gridSize * 12 * 3.5;
  float highestBudget = movies_table.getRow(movies_table.getRowCount() - 1).getFloat("budget");
  for (TableRow row : movies_table.rows()) {
    String[] dateParts = row.getString("release_date").split("/");
    int year = Integer.parseInt(dateParts[2]);
    int month = Integer.parseInt(dateParts[0]);
    String key = year + "/" + month;
    color c = lerpColor(color(255,0,0), color(0,255,0), map(row.getFloat("revenue")/row.getFloat("budget"), 0, 3, 0, 1));
    scatterNodes.put(key, new Node("scat", row.getString("title"), c, 10, new PVector(width/15 + (year-minYear)*gridSize*6 + (month-1)*((gridSize*6)/12) ,  baseHeight - map(row.getFloat("budget"), 0, highestBudget, 0, yAxisLength), 0)));
  }
}

void drawScatterPlot() {
  stroke(0,255);
  strokeWeight(1);
  textSize(10);
  int numMonths = 10;
  int numYears = maxYear - minYear;
  float baseHeight = height*0.8;
  // x-axis (release)
  float xAxisLength = (numYears+1) * gridSize * 6;
  line(width/15, baseHeight, width/15 + xAxisLength, baseHeight);
  // y-axis (budget)
  float yAxisLength = gridSize * numMonths * 3.5;
  line(width/15, baseHeight, width/15, baseHeight - yAxisLength);
  // x-ticks
  fill(0);
  for (int i = 0; i <= numYears; i++) {
    float x = width/15 + i * gridSize * 6;
    line(x, baseHeight, x, baseHeight + 8); 
    text(minYear+i, x+1+gridSize/2, baseHeight + 12);
  }
  // y-ticks
  float highestBudget = 3.5E8;
  float lowestBudget = movies_table.getRow(0).getFloat("budget");
  for (int i = 0; i <= numMonths; i++) {
    float y = baseHeight - (i) * gridSize * 3.5;
    line(width/15, y, width/15 - 5, y);
    String tick = String.format("%.0f", ((highestBudget/1.E6)*i)/numMonths);
    text(tick + " million", width/15 - 50, y+2);
  }
  textSize(25);
  text("Movie Budget", width/15 - 50, baseHeight - 11 * gridSize * 3.5);
}

void drawBackground() {
  // title
  textSize(36);
  fill(0);
  text("'Fame, Films & Finance'", width-width*.27, height*.05);
  textSize(28);
  text("By", width-width*.2, height*.075);
  text("Cornel Jonathan Cicai - 19335265", width-width*.27, height*.095);

  stroke(0,255);
  strokeWeight(1);
  int numMonths = 12;
  int numYears = maxYear - minYear;
  textSize(10);
  // x-axis (years)
  float xAxisLength = (numYears+1) * gridSize * 6;
  line(width/15, height*.5, width/15 + xAxisLength, height*.5);

  // y-axis (months)
  float yAxisLength = gridSize * 12 * 3.5;
  line(width/15, height*.5, width/15, height*.5 - yAxisLength);

  // Ticks on x-axis
  fill(0);
  for (int i = 0; i <= numYears; i++) {
    float x = width/15 + i * gridSize * 6;
    line(x, height*.5, x, height*.5 + 8); 
    text(minYear+i, x+1+gridSize/2, height*.5 + 12);
  }
  String[] months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Oct", "Sep", "Nov", "Dec"};
  // Ticks on y-axis
  for (int i = 1; i <= numMonths; i++) {
    float y = height*.5 - i * gridSize * 2.5;
    line(width/15, y, width/15 - 5, y);
    text(months[months.length - i], width/15 - 30, y+2);
  }
}

void drawOverview() {
  stroke(0);
  strokeWeight(1);
  fill(255);
  rect(width*.7, height*.4, width*.25, height*.55);
  textSize(20);
  fill(0);
  String title = selectedMovie!=null?"'" + selectedMovie.getString("title") + "'": "";
  String budget = selectedMovie!=null? String.format("Budget: $%.0f million", (selectedMovie.getFloat("budget")/1.E6)) : "";
  String rating = selectedMovie!=null? "Rating: " + selectedMovie.getString("vote_average") + "/10" : "";
  String revenue = selectedMovie!=null? String.format("Revenue: $%.0f million", (selectedMovie.getFloat("revenue")/1.E6)) : "";
  String overview = selectedMovie!=null? selectedMovie.getString("overview") : "";
  textSize(28);
  text(title, width*.7, height*.4 + 25, width*.2, height*.2);
  textSize(20);
  text(budget, width*.7, height*.45 +45);
  text(revenue, width*.7, height*.45  +65);
  text(rating, width*.7, height *.45 + 85);
  text(overview, width*.7, height*.5 + 85, width*.225, height*.3);
}

void drawLegends() {
  // actor 
  stroke(1);
  strokeWeight(2);
  fill(male);
  circle(width * .7, height *.06, 30);
  fill(female);
  circle(width * .7, height *.1+10, 30);
  fill(255);
  circle(width * .7, height *.15, 5 + 1 * 5);
  circle(width * .7, height *.21, 5 + 15 * 5);
  fill(0);
  textSize(15);
  text("Actor", width * .6925, height*.085);
  text("Actress", width * .69, height*.125+10);
  text("1 Movie", width * .69, height*.165+5);
  text("15 Movies", width * .685, height*.26);


  // movie heatmap
  setGradient(width * .65, height *.5, 10, 200, color(255,0,0), color(0,255,0), "<4", "10", "Movie Rating");
  // revenue heatmap
  setGradient(width * .65, height *.8, 10, 200, color(255,0,0), color(0,255,0), "0", ">5x", "Revenue Ratio");
}

class Node {
  public String nodeType; // can be: "act", "mov", "dir"
  public String name;
  public color c;
  public float size;
  public PVector position;
  public boolean visible;
  public boolean selected;
  public HashMap<Node, Integer> connections;
  public HashMap<Node, Integer> copiedConnections;

  Node(String nodeType, String name, color c, float size, PVector position) {
    this.nodeType = nodeType;
    this.name = name;
    this.c = c;
    this.size = size;
    this.position = position;
    this.connections = new HashMap<Node, Integer>();
    this.copiedConnections = new HashMap();
    this.visible = true;
  }

  public List<Node> getNeighbours() {
    HashSet<Node> allConnections = new HashSet();
    allConnections.addAll(connections.keySet());
    allConnections.addAll(copiedConnections.keySet());
    return allConnections.stream()
            .filter(n -> n.nodeType.equals(this.nodeType)).collect(Collectors.toList());
  }

  @Override
  public boolean equals(Object other) {
    if (other instanceof Node) {
      Node otherNode = (Node) other;
      return this.name
        .equals(otherNode.name);
    }
    return false;
  }

  @Override
  public int hashCode() {
    return this.name.hashCode();
  }

  void addConnection(Node node) {
    if(connections.containsKey(node)) {
      connections.put(node, connections.get(node)+1);
    } else {
      connections.put(node, 1);
    }
  }

  void addCopyConnection(Node node) {
    if(copiedConnections.containsKey(node)) {
      copiedConnections.put(node, copiedConnections.get(node)+1);
    } else {
      copiedConnections.put(node, 1);
    }
  }
}

// modified from https://processing.org/examples/lineargradient.html
void setGradient(float x, float y, float w, float h, color c1, color c2, String botTick, String topTick, String label ) {
  noFill();
  // bottom to top gradient
  textSize(20);
  text(botTick, x, y + 20);
  for (float i = y; i >= y-h; i-=0.1) {
    float inter = map(i, y, y-h, 0, 1);
    color c = lerpColor(c1, c2, inter);
    stroke(c);
    line(x, i, x+w, i);
  }
  text(topTick, x, y - h - 10);
  stroke(0);
  rect(x,y-h,w,h);
  pushMatrix();
  translate(x + w + 5, y - h*3/4);
  fill(0);
  rotate(radians(90));
  text(label,0, 0);
  popMatrix();
}

