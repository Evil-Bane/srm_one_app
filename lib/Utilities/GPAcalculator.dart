import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GpaCalculatorPage extends StatefulWidget {
  @override
  _GpaCalculatorPageState createState() => _GpaCalculatorPageState();
}

class _GpaCalculatorPageState extends State<GpaCalculatorPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> creditControllers = List.generate(5, (_) => TextEditingController());
  final List<String> selectedGrades = List.generate(5, (_) => "O");
  final Map<String, double> gradePoints = {
    "O": 10.0,
    "A+": 9.0,
    "A": 8.0,
    "B+": 7.0,
    "B": 6.0,
    "C": 5.5,
    "W": 0.0,
    "F": 0.0,
    "Ab": 0.0,
    "I": 0.0,
    "*": 0.0,
  };

  double sgpa = 0.0;
  late AnimationController _animationController;
  late Animation<double> _gpaAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _gpaAnimation = Tween<double>(begin: 0, end: sgpa).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void calculateSGPA() {
    double totalCredits = 0.0;
    double totalPoints = 0.0;

    for (int i = 0; i < creditControllers.length; i++) {
      double credits = double.tryParse(creditControllers[i].text) ?? 0.0;
      double gradePoint = gradePoints[selectedGrades[i]] ?? 0.0;
      totalCredits += credits;
      totalPoints += credits * gradePoint;
    }

    setState(() {
      sgpa = totalCredits == 0 ? 0 : totalPoints / totalCredits;
      _gpaAnimation = Tween<double>(begin: _gpaAnimation.value, end: sgpa).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
      );
      _animationController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GPA Calculator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _gpaAnimation,
              builder: (context, child) {
                return Container(
                  height: 200,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 10,
                        interval: 1,
                        radiusFactor: 1,
                        axisLineStyle: AxisLineStyle(
                          thickness: 0.1,
                          color: Colors.white,
                          thicknessUnit: GaugeSizeUnit.factor,
                        ),
                        pointers: <GaugePointer>[
                          RangePointer(
                            value: _gpaAnimation.value,
                            width: 0.1,
                            color: Colors.blue,
                            cornerStyle: CornerStyle.bothCurve,
                            sizeUnit: GaugeSizeUnit.factor,
                          ),
                        ],
                        annotations: <GaugeAnnotation>[
                          GaugeAnnotation(
                            positionFactor: 0.05,
                            widget: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_gpaAnimation.value.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,

                                  ),
                                ),
                                Text(
                                  'GPA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: creditControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Credits',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),

                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: DropdownButton<String>(
                                value: selectedGrades[index],
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedGrades[index] = newValue!;
                                  });
                                },
                                items: gradePoints.keys.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  );
                                }).toList(),
                                isExpanded: true,
                                underline: SizedBox(),
                                icon: Icon(Icons.arrow_drop_down),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add, size: 20, color: Colors.blue,),
                    label: Text('Add Course', style: TextStyle(color: Colors.blue),),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        creditControllers.add(TextEditingController());
                        selectedGrades.add("O");
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calculate, size: 20, color: Colors.blue,),
                    label: Text('Calculate', style: TextStyle(color: Colors.blue),),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: calculateSGPA,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}