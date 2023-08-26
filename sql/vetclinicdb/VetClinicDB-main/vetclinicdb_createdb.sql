

--create schema Customers
--go
--create schema Region
--go
--create schema Staff
--go
--create schema Patients
--go
--create schema Animals
--go
--create schema MedicalDefinitions
--go
--create schema ClassifiedMedicalData
--go

--drop table Customers.Client
--drop table Customers.PhoneNumberID
--drop table Region.City
--drop table Customers.AddressID
--drop table Staff.Doctor
--use master
--drop database VetClinicDB
--create database VetClinicDB
--go

use VetClinicDB
go


create table VetClinicDB.Patients.Patient (
	PatientID int Primary Key,
	ClientID int not null,
	PatientName nvarchar(80) not null,
	SpecieID int not null,
	Sex bit not null,
	BirthDate datetime not null,
	ReproductiveSysStatusID nvarchar(2) not null,
	WeightHistoryID int not null,
	WeightGoal decimal(5,3),
	TagNumber int,
	EssentialMedicalInfoID int not null,
	StatusID nvarchar(15) not null,
	EditDateTime datetime not null,
)
go


create table VetClinicDB.Customers.PhoneNumberID (
	PhoneNumberID int Primary Key,
	PhoneNumber1 int not null,
	PhoneNumber2 int,
	PhoneNumber3 int,
	PhoneNumber4 int,
	EditTimeDate datetime not null,
)
go

create table VetClinicDB.Region.City (
	CityID int Primary Key,
	CityName_ascii nvarchar(60) not null,
	Country nvarchar(60) not null,
	ISO nvarchar(3),
	Population int,
	EditDateTime datetime not null,
)
go

create table VetClinicDB.Customers.AddressID (
	AddressID int Primary Key,

	CityID1 int not null,
	StreetName1 nvarchar(80) not null,
	StreetNumber1 int not null,

	CityID2 int,
	StreetName2 nvarchar(80),
	StreetNumber2 int,

	CityID3 int,
	StreetName3 nvarchar(80),
	StreetNumber3 int,

	EditDateTime datetime not null,
	constraint FK_AddressID_CityID1 foreign key (CityID1) references Region.City(CityID),
	constraint FK_AddressID_CityID2	foreign key (CityID2) references Region.City(CityID),
	constraint FK_AddressID_CityID3	foreign key (CityID3) references Region.City(CityID)

)
go

create table VetClinicDB.Staff.Doctor (
	DoctorID int Primary Key,
	DoctorName nvarchar(60) not null,
	DVM_ID int not null,
	HireDate datetime,
	BirthDate datetime,
	Gender nvarchar(10),
	Role nvarchar(25) not null, -- Intern, Student, Director, Head of Deparment, Senior, Junior etc.
	Speciality nvarchar(40),
	EditDateTime datetime not null
)
go

create table VetClinicDB.Animals.Class (
	ClassID int Primary Key,
	ClassName nvarchar(15) not null,
	ClassQuantity int not null,
	ClassLimitations nvarchar(MAX),
	EditDateTime datetime not null
)
go


create table VetClinicDB.Animals.Specie (
	SpecieID int Primary Key,
	ClassID int not null,
	SpecieName nvarchar(80) not null,
	SpecieISO nvarchar(3) not null,
	SpecieLimitations nvarchar(MAX),
	EditDateTime datetime not null,
	constraint FK_Specie_ClassID foreign key (ClassID) references Animals.Class(ClassID)
)
go


create table VetClinicDB.Patients.WeightHistory (
	WeightHistoryID int Primary Key,
	PatientID int not null,
	WeightRecorded Decimal(5,3) not null,
	EditDateTime datetime not null,
	constraint FK_WeightHistory_PatientID foreign key (PatientID) references Patients.Patient(PatientID)
)
go


create table VetClinicDB.MedicalDefinitions.ReproductiveSystemStatus (
	StatusID nvarchar(2) Primary Key, --SF, CM, M, F
	StatusGender nvarchar(20),
	StatusName nvarchar(20),
	EditDateTime datetime not null
)
go

create table VetClinicDB.ClassifiedMedicalData.VaccinationHistory (
	VaccinationHistoryID int Primary Key,
	PatientID int not null,
	RabiesVaccination datetime,
	DAPPvCv1 datetime,
	DAPPvCv2 datetime,
	DAPPvCv3 datetime,
	DAPPvCv4 datetime,
	DAPPvCvExtra datetime,
	Parvo1 datetime,
	Parvo2 datetime,
	ParvoExtra datetime,
	DectoMax datetime,
	DewormingName nvarchar(25),
	Deworming datetime,
	AntiParasiteName nvarchar(25),
	AntiParasite datetime,
	constraint FK_VaccinationHistory_PatientID foreign key (PatientID) references Patients.Patient(PatientID)
)
go



create table VetClinicDB.ClassifiedMedicalData.EssentialMedicalInfo (
	EssentialMedicalInfoID int Primary Key,
	VaccinationHistoryID int not null,
	Allergies nvarchar(300),
	Comment nvarchar(250),
	EditDateTime datetime not null,
	constraint FK_EssentialMedicalInfo_VaccinationHistoryID foreign key (VaccinationHistoryID) references ClassifiedMedicalData.VaccinationHistory(VaccinationHistoryID)
)
go


create table VetClinicDB.MedicalDefinitions.PatientStatus (
	StatusID nvarchar(15) Primary Key, -- Hospitalized, Healthy, OnWatch, InTreatment, Deceased
	StatusMeaning nvarchar(150),
	EditDateTime datetime not null
)	
go


create table VetClinicDB.ClassifiedMedicalData.PatientStatusHistory (
	StatusHistoryID int Primary Key,
	PatientID int not null,
	StatusID nvarchar(15) not null,
	EditDateTime datetime not null,
	constraint FK_PatientStatusHistory_StatusID foreign key (StatusID) references MedicalDefinitions.PatientStatus(StatusID),
	constraint FK_PatientStatusHistory_PatientID foreign key (PatientID) references Patients.Patient(PatientID)
)	
go


alter table Patients.Patient add
	constraint FK_Patient_SpecieID foreign key (SpecieID) references Animals.Specie(SpecieID),
	constraint FK_Patient_WeightHistoryID foreign key (WeightHistoryID) references Patients.WeightHistory(WeightHistoryID),
	constraint FK_Patient_ReproSysStatusID foreign key (ReproductiveSysStatusID) references MedicalDefinitions.ReproductiveSystemStatus(StatusID),
	constraint FK_Patient_EssentialMedicalInfoID foreign key (EssentialMedicalInfoID) references ClassifiedMedicalData.EssentialMedicalInfo(EssentialMedicalInfoID),
	constraint FK_Patient_StatusID foreign key (StatusID) references MedicalDefinitions.PatientStatus(StatusID)



create table VetClinicDB.Customers.Client (
	ClientID int Primary Key,
	ClientName nvarchar(60) not null,
	CitizenID int not null,
	PhoneNumberID int not null,
	AddressID int not null,
	EmailID int,
	DoctorID int,
	PatientID int,
	IsExternalClient bit not null,
	EditDateTime datetime not null,
	constraint FK_Client_PhoneNumberID foreign key (PhoneNumberID) references Customers.PhoneNumberID(PhoneNumberID),
	constraint FK_Client_AddressID foreign key (AddressID) references Customers.AddressID(AddressID),
	constraint FK_Client_DoctorID foreign key (DoctorID) references Staff.Doctor(DoctorID),
	constraint FK_Client_PatientID foreign key (PatientID) references Patients.Patient(PatientID)
)
go