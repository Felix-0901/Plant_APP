import 'package:flutter/material.dart';

class Greenhouse extends StatefulWidget {
  const Greenhouse({Key? key}) : super(key: key);

  @override
  State<Greenhouse> createState() => _GreenhouseState();
}

class _GreenhouseState extends State<Greenhouse> {
  void add_plant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 1000,
          color: Colors.white,
          child: Center(
            child: Column(
              
              children: [
                SizedBox(
                  height: 50,
                ),
                SizedBox(
                  width: 300,
                  child: Text(
                    "植物品種",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: 300,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),


                SizedBox(
                  width: 300,
                  child: Text(
                    "暱稱",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: 300,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false, // 設為 true 時可撐滿高度
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => add_plant(context),
        child: Icon(Icons.add)
        ),
      appBar: AppBar(
        title: Text('溫室'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}