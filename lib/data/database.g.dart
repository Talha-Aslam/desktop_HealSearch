// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MedicinesTable extends Medicines
    with TableInfo<$MedicinesTable, Medicine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pharmacyIdMeta =
      const VerificationMeta('pharmacyId');
  @override
  late final GeneratedColumn<String> pharmacyId = GeneratedColumn<String>(
      'pharmacy_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _genericNameMeta =
      const VerificationMeta('genericName');
  @override
  late final GeneratedColumn<String> genericName = GeneratedColumn<String>(
      'generic_name', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
      'stock', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, pharmacyId, name, genericName, category, price, stock, expiryDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medicines';
  @override
  VerificationContext validateIntegrity(Insertable<Medicine> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pharmacy_id')) {
      context.handle(
          _pharmacyIdMeta,
          pharmacyId.isAcceptableOrUnknown(
              data['pharmacy_id']!, _pharmacyIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('generic_name')) {
      context.handle(
          _genericNameMeta,
          genericName.isAcceptableOrUnknown(
              data['generic_name']!, _genericNameMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    } else if (isInserting) {
      context.missing(_stockMeta);
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medicine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medicine(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pharmacyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pharmacy_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      genericName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}generic_name']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock'])!,
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expiry_date']),
    );
  }

  @override
  $MedicinesTable createAlias(String alias) {
    return $MedicinesTable(attachedDatabase, alias);
  }
}

class Medicine extends DataClass implements Insertable<Medicine> {
  final int id;
  final String? pharmacyId;
  final String name;
  final String? genericName;
  final String? category;
  final double price;
  final int stock;
  final DateTime? expiryDate;
  const Medicine(
      {required this.id,
      this.pharmacyId,
      required this.name,
      this.genericName,
      this.category,
      required this.price,
      required this.stock,
      this.expiryDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || pharmacyId != null) {
      map['pharmacy_id'] = Variable<String>(pharmacyId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || genericName != null) {
      map['generic_name'] = Variable<String>(genericName);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['price'] = Variable<double>(price);
    map['stock'] = Variable<int>(stock);
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    return map;
  }

  MedicinesCompanion toCompanion(bool nullToAbsent) {
    return MedicinesCompanion(
      id: Value(id),
      pharmacyId: pharmacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pharmacyId),
      name: Value(name),
      genericName: genericName == null && nullToAbsent
          ? const Value.absent()
          : Value(genericName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      price: Value(price),
      stock: Value(stock),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
    );
  }

  factory Medicine.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medicine(
      id: serializer.fromJson<int>(json['id']),
      pharmacyId: serializer.fromJson<String?>(json['pharmacyId']),
      name: serializer.fromJson<String>(json['name']),
      genericName: serializer.fromJson<String?>(json['genericName']),
      category: serializer.fromJson<String?>(json['category']),
      price: serializer.fromJson<double>(json['price']),
      stock: serializer.fromJson<int>(json['stock']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pharmacyId': serializer.toJson<String?>(pharmacyId),
      'name': serializer.toJson<String>(name),
      'genericName': serializer.toJson<String?>(genericName),
      'category': serializer.toJson<String?>(category),
      'price': serializer.toJson<double>(price),
      'stock': serializer.toJson<int>(stock),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
    };
  }

  Medicine copyWith(
          {int? id,
          Value<String?> pharmacyId = const Value.absent(),
          String? name,
          Value<String?> genericName = const Value.absent(),
          Value<String?> category = const Value.absent(),
          double? price,
          int? stock,
          Value<DateTime?> expiryDate = const Value.absent()}) =>
      Medicine(
        id: id ?? this.id,
        pharmacyId: pharmacyId.present ? pharmacyId.value : this.pharmacyId,
        name: name ?? this.name,
        genericName: genericName.present ? genericName.value : this.genericName,
        category: category.present ? category.value : this.category,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
      );
  Medicine copyWithCompanion(MedicinesCompanion data) {
    return Medicine(
      id: data.id.present ? data.id.value : this.id,
      pharmacyId:
          data.pharmacyId.present ? data.pharmacyId.value : this.pharmacyId,
      name: data.name.present ? data.name.value : this.name,
      genericName:
          data.genericName.present ? data.genericName.value : this.genericName,
      category: data.category.present ? data.category.value : this.category,
      price: data.price.present ? data.price.value : this.price,
      stock: data.stock.present ? data.stock.value : this.stock,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medicine(')
          ..write('id: $id, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('name: $name, ')
          ..write('genericName: $genericName, ')
          ..write('category: $category, ')
          ..write('price: $price, ')
          ..write('stock: $stock, ')
          ..write('expiryDate: $expiryDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, pharmacyId, name, genericName, category, price, stock, expiryDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medicine &&
          other.id == this.id &&
          other.pharmacyId == this.pharmacyId &&
          other.name == this.name &&
          other.genericName == this.genericName &&
          other.category == this.category &&
          other.price == this.price &&
          other.stock == this.stock &&
          other.expiryDate == this.expiryDate);
}

class MedicinesCompanion extends UpdateCompanion<Medicine> {
  final Value<int> id;
  final Value<String?> pharmacyId;
  final Value<String> name;
  final Value<String?> genericName;
  final Value<String?> category;
  final Value<double> price;
  final Value<int> stock;
  final Value<DateTime?> expiryDate;
  const MedicinesCompanion({
    this.id = const Value.absent(),
    this.pharmacyId = const Value.absent(),
    this.name = const Value.absent(),
    this.genericName = const Value.absent(),
    this.category = const Value.absent(),
    this.price = const Value.absent(),
    this.stock = const Value.absent(),
    this.expiryDate = const Value.absent(),
  });
  MedicinesCompanion.insert({
    this.id = const Value.absent(),
    this.pharmacyId = const Value.absent(),
    required String name,
    this.genericName = const Value.absent(),
    this.category = const Value.absent(),
    required double price,
    required int stock,
    this.expiryDate = const Value.absent(),
  })  : name = Value(name),
        price = Value(price),
        stock = Value(stock);
  static Insertable<Medicine> custom({
    Expression<int>? id,
    Expression<String>? pharmacyId,
    Expression<String>? name,
    Expression<String>? genericName,
    Expression<String>? category,
    Expression<double>? price,
    Expression<int>? stock,
    Expression<DateTime>? expiryDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
      if (name != null) 'name': name,
      if (genericName != null) 'generic_name': genericName,
      if (category != null) 'category': category,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (expiryDate != null) 'expiry_date': expiryDate,
    });
  }

  MedicinesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? pharmacyId,
      Value<String>? name,
      Value<String?>? genericName,
      Value<String?>? category,
      Value<double>? price,
      Value<int>? stock,
      Value<DateTime?>? expiryDate}) {
    return MedicinesCompanion(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pharmacyId.present) {
      map['pharmacy_id'] = Variable<String>(pharmacyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (genericName.present) {
      map['generic_name'] = Variable<String>(genericName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicinesCompanion(')
          ..write('id: $id, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('name: $name, ')
          ..write('genericName: $genericName, ')
          ..write('category: $category, ')
          ..write('price: $price, ')
          ..write('stock: $stock, ')
          ..write('expiryDate: $expiryDate')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pharmacyIdMeta =
      const VerificationMeta('pharmacyId');
  @override
  late final GeneratedColumn<String> pharmacyId = GeneratedColumn<String>(
      'pharmacy_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isSyncedToCloudMeta =
      const VerificationMeta('isSyncedToCloud');
  @override
  late final GeneratedColumn<bool> isSyncedToCloud = GeneratedColumn<bool>(
      'is_synced_to_cloud', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_synced_to_cloud" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, pharmacyId, totalAmount, createdAt, isSyncedToCloud];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(Insertable<Sale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pharmacy_id')) {
      context.handle(
          _pharmacyIdMeta,
          pharmacyId.isAcceptableOrUnknown(
              data['pharmacy_id']!, _pharmacyIdMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_synced_to_cloud')) {
      context.handle(
          _isSyncedToCloudMeta,
          isSyncedToCloud.isAcceptableOrUnknown(
              data['is_synced_to_cloud']!, _isSyncedToCloudMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pharmacyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pharmacy_id']),
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isSyncedToCloud: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_synced_to_cloud'])!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final int id;
  final String? pharmacyId;
  final double totalAmount;
  final DateTime createdAt;
  final bool isSyncedToCloud;
  const Sale(
      {required this.id,
      this.pharmacyId,
      required this.totalAmount,
      required this.createdAt,
      required this.isSyncedToCloud});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || pharmacyId != null) {
      map['pharmacy_id'] = Variable<String>(pharmacyId);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_synced_to_cloud'] = Variable<bool>(isSyncedToCloud);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      id: Value(id),
      pharmacyId: pharmacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(pharmacyId),
      totalAmount: Value(totalAmount),
      createdAt: Value(createdAt),
      isSyncedToCloud: Value(isSyncedToCloud),
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      id: serializer.fromJson<int>(json['id']),
      pharmacyId: serializer.fromJson<String?>(json['pharmacyId']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isSyncedToCloud: serializer.fromJson<bool>(json['isSyncedToCloud']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pharmacyId': serializer.toJson<String?>(pharmacyId),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isSyncedToCloud': serializer.toJson<bool>(isSyncedToCloud),
    };
  }

  Sale copyWith(
          {int? id,
          Value<String?> pharmacyId = const Value.absent(),
          double? totalAmount,
          DateTime? createdAt,
          bool? isSyncedToCloud}) =>
      Sale(
        id: id ?? this.id,
        pharmacyId: pharmacyId.present ? pharmacyId.value : this.pharmacyId,
        totalAmount: totalAmount ?? this.totalAmount,
        createdAt: createdAt ?? this.createdAt,
        isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
      );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      id: data.id.present ? data.id.value : this.id,
      pharmacyId:
          data.pharmacyId.present ? data.pharmacyId.value : this.pharmacyId,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isSyncedToCloud: data.isSyncedToCloud.present
          ? data.isSyncedToCloud.value
          : this.isSyncedToCloud,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('id: $id, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSyncedToCloud: $isSyncedToCloud')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, pharmacyId, totalAmount, createdAt, isSyncedToCloud);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.id == this.id &&
          other.pharmacyId == this.pharmacyId &&
          other.totalAmount == this.totalAmount &&
          other.createdAt == this.createdAt &&
          other.isSyncedToCloud == this.isSyncedToCloud);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<int> id;
  final Value<String?> pharmacyId;
  final Value<double> totalAmount;
  final Value<DateTime> createdAt;
  final Value<bool> isSyncedToCloud;
  const SalesCompanion({
    this.id = const Value.absent(),
    this.pharmacyId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isSyncedToCloud = const Value.absent(),
  });
  SalesCompanion.insert({
    this.id = const Value.absent(),
    this.pharmacyId = const Value.absent(),
    required double totalAmount,
    this.createdAt = const Value.absent(),
    this.isSyncedToCloud = const Value.absent(),
  }) : totalAmount = Value(totalAmount);
  static Insertable<Sale> custom({
    Expression<int>? id,
    Expression<String>? pharmacyId,
    Expression<double>? totalAmount,
    Expression<DateTime>? createdAt,
    Expression<bool>? isSyncedToCloud,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pharmacyId != null) 'pharmacy_id': pharmacyId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (isSyncedToCloud != null) 'is_synced_to_cloud': isSyncedToCloud,
    });
  }

  SalesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? pharmacyId,
      Value<double>? totalAmount,
      Value<DateTime>? createdAt,
      Value<bool>? isSyncedToCloud}) {
    return SalesCompanion(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pharmacyId.present) {
      map['pharmacy_id'] = Variable<String>(pharmacyId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isSyncedToCloud.present) {
      map['is_synced_to_cloud'] = Variable<bool>(isSyncedToCloud.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('id: $id, ')
          ..write('pharmacyId: $pharmacyId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isSyncedToCloud: $isSyncedToCloud')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MedicinesTable medicines = $MedicinesTable(this);
  late final $SalesTable sales = $SalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [medicines, sales];
}

typedef $$MedicinesTableCreateCompanionBuilder = MedicinesCompanion Function({
  Value<int> id,
  Value<String?> pharmacyId,
  required String name,
  Value<String?> genericName,
  Value<String?> category,
  required double price,
  required int stock,
  Value<DateTime?> expiryDate,
});
typedef $$MedicinesTableUpdateCompanionBuilder = MedicinesCompanion Function({
  Value<int> id,
  Value<String?> pharmacyId,
  Value<String> name,
  Value<String?> genericName,
  Value<String?> category,
  Value<double> price,
  Value<int> stock,
  Value<DateTime?> expiryDate,
});

class $$MedicinesTableFilterComposer
    extends Composer<_$AppDatabase, $MedicinesTable> {
  $$MedicinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genericName => $composableBuilder(
      column: $table.genericName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnFilters(column));
}

class $$MedicinesTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicinesTable> {
  $$MedicinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genericName => $composableBuilder(
      column: $table.genericName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => ColumnOrderings(column));
}

class $$MedicinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicinesTable> {
  $$MedicinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get genericName => $composableBuilder(
      column: $table.genericName, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
      column: $table.expiryDate, builder: (column) => column);
}

class $$MedicinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MedicinesTable,
    Medicine,
    $$MedicinesTableFilterComposer,
    $$MedicinesTableOrderingComposer,
    $$MedicinesTableAnnotationComposer,
    $$MedicinesTableCreateCompanionBuilder,
    $$MedicinesTableUpdateCompanionBuilder,
    (Medicine, BaseReferences<_$AppDatabase, $MedicinesTable, Medicine>),
    Medicine,
    PrefetchHooks Function()> {
  $$MedicinesTableTableManager(_$AppDatabase db, $MedicinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pharmacyId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> genericName = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<DateTime?> expiryDate = const Value.absent(),
          }) =>
              MedicinesCompanion(
            id: id,
            pharmacyId: pharmacyId,
            name: name,
            genericName: genericName,
            category: category,
            price: price,
            stock: stock,
            expiryDate: expiryDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pharmacyId = const Value.absent(),
            required String name,
            Value<String?> genericName = const Value.absent(),
            Value<String?> category = const Value.absent(),
            required double price,
            required int stock,
            Value<DateTime?> expiryDate = const Value.absent(),
          }) =>
              MedicinesCompanion.insert(
            id: id,
            pharmacyId: pharmacyId,
            name: name,
            genericName: genericName,
            category: category,
            price: price,
            stock: stock,
            expiryDate: expiryDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MedicinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MedicinesTable,
    Medicine,
    $$MedicinesTableFilterComposer,
    $$MedicinesTableOrderingComposer,
    $$MedicinesTableAnnotationComposer,
    $$MedicinesTableCreateCompanionBuilder,
    $$MedicinesTableUpdateCompanionBuilder,
    (Medicine, BaseReferences<_$AppDatabase, $MedicinesTable, Medicine>),
    Medicine,
    PrefetchHooks Function()>;
typedef $$SalesTableCreateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  Value<String?> pharmacyId,
  required double totalAmount,
  Value<DateTime> createdAt,
  Value<bool> isSyncedToCloud,
});
typedef $$SalesTableUpdateCompanionBuilder = SalesCompanion Function({
  Value<int> id,
  Value<String?> pharmacyId,
  Value<double> totalAmount,
  Value<DateTime> createdAt,
  Value<bool> isSyncedToCloud,
});

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSyncedToCloud => $composableBuilder(
      column: $table.isSyncedToCloud,
      builder: (column) => ColumnFilters(column));
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSyncedToCloud => $composableBuilder(
      column: $table.isSyncedToCloud,
      builder: (column) => ColumnOrderings(column));
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pharmacyId => $composableBuilder(
      column: $table.pharmacyId, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isSyncedToCloud => $composableBuilder(
      column: $table.isSyncedToCloud, builder: (column) => column);
}

class $$SalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
    Sale,
    PrefetchHooks Function()> {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pharmacyId = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSyncedToCloud = const Value.absent(),
          }) =>
              SalesCompanion(
            id: id,
            pharmacyId: pharmacyId,
            totalAmount: totalAmount,
            createdAt: createdAt,
            isSyncedToCloud: isSyncedToCloud,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> pharmacyId = const Value.absent(),
            required double totalAmount,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isSyncedToCloud = const Value.absent(),
          }) =>
              SalesCompanion.insert(
            id: id,
            pharmacyId: pharmacyId,
            totalAmount: totalAmount,
            createdAt: createdAt,
            isSyncedToCloud: isSyncedToCloud,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesTable,
    Sale,
    $$SalesTableFilterComposer,
    $$SalesTableOrderingComposer,
    $$SalesTableAnnotationComposer,
    $$SalesTableCreateCompanionBuilder,
    $$SalesTableUpdateCompanionBuilder,
    (Sale, BaseReferences<_$AppDatabase, $SalesTable, Sale>),
    Sale,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MedicinesTableTableManager get medicines =>
      $$MedicinesTableTableManager(_db, _db.medicines);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
}
