import 'package:flutter/material.dart';
import 'greenhouse.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PLANT'),
        backgroundColor: Colors.grey,
      ),
      body:ListView(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.all(40),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color:Colors.blue,
              ),
            ),
          ),

          Center(
            child: SizedBox(
              width:350,
              child: Divider(
                thickness: 2,
                color:Colors.black,
              ),
            ),
          ),

          SizedBox(
            height: 30,
          ),
          Center(
            child: SizedBox(
              width: 250,
              child: ElevatedButton(
                  onPressed: (){
                    Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => Greenhouse()),
                  );
                }, 
                style: ElevatedButton.styleFrom (
                  side:BorderSide(color:Colors.black),
                  padding: EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  "前往溫室",
                  style:TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
