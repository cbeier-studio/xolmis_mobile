import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/providers/inventory_provider.dart';

import '../../data/models/inventory.dart';
import '../../providers/egg_provider.dart';
import '../../providers/nest_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/specimen_provider.dart';
import '../../generated/l10n.dart';

import 'stats_general_tab.dart';
import 'stats_species_tab.dart';

class StatsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const StatsScreen({super.key, required this.scaffoldKey});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late InventoryProvider inventoryProvider;
  late SpeciesProvider speciesProvider;
  late PoiProvider poiProvider;
  late NestProvider nestProvider;
  late EggProvider eggProvider;
  late SpecimenProvider specimenProvider;
  List<Species> allSpeciesList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    poiProvider = Provider.of<PoiProvider>(context, listen: false);
    nestProvider = Provider.of<NestProvider>(context, listen: false);
    eggProvider = Provider.of<EggProvider>(context, listen: false);
    specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(S.current.statistics),
            leading:
            MediaQuery.sizeOf(context).width < 600
                ? Builder(
              builder:
                  (context) => IconButton(
                icon: const Icon(Icons.menu_outlined),
                onPressed: () {
                  widget.scaffoldKey.currentState?.openDrawer();
                },
              ),
            )
                : SizedBox.shrink(),
            bottom: TabBar(
              controller: _tabController,
              tabs: [Tab(text: S.current.general), Tab(text: S.current.perSpecies)],
            ),
        ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: NeverScrollableScrollPhysics(),
          children: [
            StatsGeneralTab(
              nestProvider: nestProvider,
              eggProvider: eggProvider,
              specimenProvider: specimenProvider,
              inventoryProvider: inventoryProvider,
              poiProvider: poiProvider,
              allSpeciesList: allSpeciesList,
            ),
            StatsSpeciesTab(
              inventoryProvider: inventoryProvider,
              speciesProvider: speciesProvider,
              nestProvider: nestProvider,
              eggProvider: eggProvider,
              specimenProvider: specimenProvider,
            )
          ],
        ),
      ),
    );
  }

}