# ORM Sampler

This is a simple project comparing the use of ActiveRecord, DataMapper, and Sequel on a collection of four models with has_many
relationships.

## The Data Model

    Business
     |
     -->> Days (virtual)
     |     |
     |     -->> Shifts
     |           |
     |           ---->> Appointments <--> Usage
     |             |
     -->> Holidays |
           |       |
           -->> HolidayShifts < Shifts

## The Goal

A Business is open on some days. On those days, the workers work some shifts. Each shift has a certain number of appointment slots
available for customers to come in and interact with the business. The goal for this little sampler is to be able to get a list of
all available appointments for a business on a given day between two time points.


## The Approach

All development is done according to a TDD methodology. Rake tasks exist for creating the Database, migrating the schema, and
populating with dummy data.


## TODO

1. Setup Guard and Rspec
2. Construct Business Objects to encapsulate logic (? with in memory logic ?)
3. Create a means to switch ORM engine for BOs
4. TDD Development of BOs (with ORM development in Sequel)
5. Fill out ORM logic for DM
6. Fill out ORM logic for AR
