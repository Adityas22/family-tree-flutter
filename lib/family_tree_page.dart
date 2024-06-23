import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'model/database_helper.dart';
import 'login_screen.dart';

class FamilyTreePage extends StatefulWidget {
  final int userId;

  FamilyTreePage({required this.userId});

  @override
  _FamilyTreePageState createState() => _FamilyTreePageState();
}

class _FamilyTreePageState extends State<FamilyTreePage> {
  final List<FamilyMember> familyMembers = [];
  final nameController = TextEditingController();
  String gender = 'Male';

  final Graph graph = Graph();
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  Node? selectedNode;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = (100)
      ..levelSeparation = (150)
      ..subtreeSeparation = (150)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    var db = DatabaseHelper.instance;
    var members = await db.getFamilyMembers(widget.userId);

    setState(() {
      for (var member in members) {
        familyMembers.add(
          FamilyMember(
            member['name'],
            member['gender'],
            id: member['id'],
            parent: member['parent_id'] != null
                ? familyMembers.firstWhere((m) => m.id == member['parent_id'])
                : null,
          ),
        );
      }
      _buildGraph();
    });
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();

    Map<int, Node> nodeMap = {};

    for (var member in familyMembers) {
      var node = Node.Id(member);
      graph.addNode(node);
      nodeMap[member.id] = node;
    }

    for (var member in familyMembers) {
      if (member.parent != null) {
        var parentNode = nodeMap[member.parent!.id];
        var childNode = nodeMap[member.id];
        if (parentNode != null && childNode != null) {
          graph.addEdge(parentNode, childNode);
        }
      }
    }

    setState(() {}); // Force a redraw
  }

  Future<void> addFamilyMember() async {
    if (nameController.text.isEmpty) {
      return;
    }

    var db = DatabaseHelper.instance;

    var parentId = selectedNode != null
        ? (selectedNode!.key?.value as FamilyMember).id
        : null;

    var id = await db.createFamilyMember(
      nameController.text,
      gender,
      widget.userId,
      parentId: parentId,
    );

    setState(() {
      var newMember = FamilyMember(
        nameController.text,
        gender,
        id: id,
        parent: parentId != null
            ? familyMembers.firstWhere((m) => m.id == parentId)
            : null,
      );
      familyMembers.add(newMember);
      selectedNode = null; // Clear the selected node after adding a new member
      nameController.clear();
      _buildGraph();
    });
  }

  Future<void> editFamilyMember(FamilyMember member) async {
    var db = DatabaseHelper.instance;

    await db.updateFamilyMember(
      member.id,
      nameController.text.isNotEmpty ? nameController.text : member.name,
      gender,
    );

    setState(() {
      member.name =
          nameController.text.isNotEmpty ? nameController.text : member.name;
      member.gender = gender;
      nameController.clear();
      _buildGraph();
    });
  }

  Future<void> deleteFamilyMember(FamilyMember member) async {
    var db = DatabaseHelper.instance;

    await db.deleteFamilyMember(member.id);

    setState(() {
      familyMembers.remove(member);
      selectedNode = null; // Clear the selected node when a member is deleted
      _buildGraph();
    });
  }

  void _zoomIn() {
    setState(() {
      _currentScale += 0.1;
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 0.1).clamp(0.1, 5.6);
    });
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Tree'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.white.withOpacity(0.8),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButton<String>(
                          value: gender,
                          onChanged: (String? newValue) {
                            setState(() {
                              gender = newValue!;
                            });
                          },
                          items: <String>['Male', 'Female']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        Wrap(
                          spacing: 8.0, // gap between adjacent chips
                          runSpacing: 4.0, // gap between lines
                          children: [
                            ElevatedButton(
                              onPressed: addFamilyMember,
                              child: Text(familyMembers.isEmpty
                                  ? 'Add Root Member'
                                  : 'Add Family Member'),
                            ),
                            if (selectedNode != null)
                              ElevatedButton(
                                onPressed: () {
                                  var member =
                                      selectedNode!.key?.value as FamilyMember;
                                  editFamilyMember(member);
                                },
                                child: Text('Edit Member'),
                              ),
                            if (selectedNode != null)
                              ElevatedButton(
                                onPressed: () {
                                  var member =
                                      selectedNode!.key?.value as FamilyMember;
                                  deleteFamilyMember(member);
                                },
                                child: Text('Delete Member'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_out),
                    onPressed: _zoomOut,
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in),
                    onPressed: _zoomIn,
                  ),
                ],
              ),
              Expanded(
                child: familyMembers.isEmpty
                    ? Center(
                        child: Text(
                          'Please add the first family member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : InteractiveViewer(
                        constrained: false,
                        boundaryMargin: EdgeInsets.all(20),
                        minScale: 0.01,
                        maxScale: 5.6,
                        scaleEnabled: false,
                        child: Transform.scale(
                          scale: _currentScale,
                          child: GraphView(
                            graph: graph,
                            algorithm: BuchheimWalkerAlgorithm(
                                builder, TreeEdgeRenderer(builder)),
                            builder: (Node node) {
                              var member = node.key?.value as FamilyMember;
                              return rectangleWidget(member, node);
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget rectangleWidget(FamilyMember member, Node node) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedNode = node;
          nameController.text = member.name;
          gender = member.gender;
        });
        print('Node ${member.name} clicked');
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: selectedNode == node ? Colors.red : Colors.blueAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(
              member.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(member.gender),
          ],
        ),
      ),
    );
  }
}

class FamilyMember {
  final int id;
  String name;
  String gender;
  FamilyMember? parent;

  FamilyMember(this.name, this.gender, {required this.id, this.parent});
}
